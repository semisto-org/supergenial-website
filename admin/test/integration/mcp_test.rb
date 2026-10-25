require "test_helper"

class McpTest < ActionDispatch::IntegrationTest
  REDIRECT_URI = "https://claude.ai/api/mcp/auth_callback".freeze

  setup { host! "admin.example.com" }

  test "discovery documents point to the authorization server" do
    get "/.well-known/oauth-protected-resource/mcp"
    assert_equal "http://admin.example.com/mcp", response.parsed_body["resource"]

    get "/.well-known/oauth-authorization-server"
    metadata = response.parsed_body
    assert_equal "http://admin.example.com/oauth/token", metadata["token_endpoint"]
    assert_equal [ "S256" ], metadata["code_challenge_methods_supported"]
  end

  test "mcp requires a bearer token and advertises the resource metadata" do
    post mcp_path, params: initialize_request, as: :json
    assert_response :unauthorized
    assert_match %r{resource_metadata="http://admin.example.com/.well-known/oauth-protected-resource/mcp"}, response.headers["WWW-Authenticate"]

    post mcp_path, params: initialize_request, as: :json, headers: { "Authorization" => "Bearer sga_forged" }
    assert_response :unauthorized
  end

  test "registration refuses unsafe redirect URIs" do
    post oauth_registration_path, params: { client_name: "Evil", redirect_uris: [ "http://evil.example/callback" ] }, as: :json
    assert_response :bad_request
    assert_equal "invalid_client_metadata", response.parsed_body["error"]
  end

  test "full OAuth flow then tool calls" do
    tokens = authorize_and_get_tokens
    assert tokens["access_token"].start_with?("sga_")

    mcp(tokens["access_token"], initialize_request)
    assert_equal "supergenial-admin", response.parsed_body.dig("result", "serverInfo", "name")

    mcp(tokens["access_token"], { jsonrpc: "2.0", id: 2, method: "tools/list" })
    tools = response.parsed_body.dig("result", "tools").index_by { |tool| tool["name"] }
    assert_equal AdminMcp.tools.size, tools.size
    assert tools.dig("search_clients", "annotations", "readOnlyHint")
    assert tools.dig("delete_client", "annotations", "destructiveHint")

    result = call_tool(tokens["access_token"], "search_clients", query: "silv")
    assert_equal [ "Silvéa" ], result.dig("structuredContent", "clients").map { |client| client["name"] }

    result = call_tool(tokens["access_token"], "save_time_entry", client_id: clients(:dici).id, performed_on: "2026-10-24", hours: 2, description: "Call")
    entry_id = result.dig("structuredContent", "time_entry", "id")
    assert_equal "a_facturer", TimeEntry.find(entry_id).status

    result = call_tool(tokens["access_token"], "bill_time_entries", ids: [ entry_id, time_entries(:visio).id ])
    invoice = result.dig("structuredContent", "invoice")
    assert_equal [ "draft", 280.0, 2 ], [ invoice["status"], invoice["amount_excl_vat"], invoice["lines"].size ]
    assert TimeEntry.find(entry_id).facture?
  end

  test "changes made through Claude are recorded in the audit log" do
    token = issue_token
    call_tool(token, "save_client", id: clients(:dici).id, notes: "Via Claude")

    event = AuditEvent.where(auditable: clients(:dici)).last
    assert_equal "claude_mcp", event.actor_kind
    assert_equal users(:one), event.user
  end

  test "the accountant only gets read-only tools" do
    token = issue_token(users(:accountant))
    mcp(token, { jsonrpc: "2.0", id: 2, method: "tools/list" })
    names = response.parsed_body.dig("result", "tools").map { |tool| tool["name"] }
    assert_includes names, "search_clients"
    assert_not_includes names, "save_client"

    mcp(token, { jsonrpc: "2.0", id: 3, method: "tools/call", params: { name: "delete_client", arguments: { id: clients(:dici).id } } })
    assert Client.exists?(clients(:dici).id)
  end

  test "draft invoices are written line by line, then deleted" do
    token = issue_token

    result = call_tool(token, "save_invoice", client_id: clients(:dici).id, label: "Atelier",
                                              lines: [ { description: "Atelier IA", quantity: 1, unit: "day", unit_price: 600 } ])
    invoice = result.dig("structuredContent", "invoice")
    assert_equal [ "draft", 600.0, 126.0 ], [ invoice["status"], invoice["amount_excl_vat"], invoice["vat_amount"] ]

    result = call_tool(token, "save_invoice", id: invoice["id"], lines: [ { description: "Atelier IA", quantity: 2, unit: "day", unit_price: 600 },
                                                                          { description: "Déplacement", quantity: 1, unit_price: 50 } ])
    assert_equal 1250.0, result.dig("structuredContent", "invoice", "amount_excl_vat")
    assert_equal 2, Invoice.find(invoice["id"]).lines.count

    call_tool(token, "delete_invoice", id: invoice["id"])
    assert_not Invoice.exists?(invoice["id"])
  end

  test "tool errors are reported to Claude, not raised" do
    token = issue_token

    result = call_tool(token, "save_client", name: "")
    assert result["isError"]

    result = call_tool(token, "get_client", id: 0)
    assert result["isError"]

    clients(:dici).invoices.create!(label: "Site", amount: 100, issued_on: Date.current)
    result = call_tool(token, "delete_client", id: clients(:dici).id)
    assert result["isError"]
    assert Client.exists?(clients(:dici).id)
  end

  test "save tools create then update, and plans get their first price" do
    token = issue_token

    result = call_tool(token, "save_plan", name: "Croissance", period: "mensuel", first_price: 1200)
    plan_id = result.dig("structuredContent", "plan", "id")
    assert_equal 1200.0, result.dig("structuredContent", "plan", "current_price")

    call_tool(token, "add_plan_price", plan_id:, amount: 1300, starts_on: "2027-01-01")
    assert_equal 2, Plan.find(plan_id).prices.count

    result = call_tool(token, "save_contract", client_id: clients(:dici).id, label: "Maintenance", kinds: [ "maintenance" ], plan_id:)
    contract = Contract.find(result.dig("structuredContent", "contract", "id"))
    assert_equal 1200, contract.current_amount

    call_tool(token, "save_contract", id: contract.id, amount: 1000)
    assert contract.reload.negotiated?

    result = call_tool(token, "add_hourly_rate", amount: 95, starts_on: "2027-07-01")
    assert_equal 95.0, result.dig("structuredContent", "hourly_rate", "amount")
    result = call_tool(token, "list_hourly_rates")
    assert_equal "2027-01-01", result.dig("structuredContent", "next_change", "starts_on")
  end

  test "authorization codes are single use and need the PKCE verifier" do
    client = register_client
    verifier = SecureRandom.urlsafe_base64(48)

    sign_in_as users(:one)
    post oauth_authorization_path, params: authorization_params(client, verifier).merge(decision: "approve")
    code = Rack::Utils.parse_query(URI.parse(response.location).query)["code"]

    post oauth_token_path, params: { grant_type: "authorization_code", client_id: client["client_id"], code:, redirect_uri: REDIRECT_URI, code_verifier: "wrong" }
    assert_equal "invalid_grant", response.parsed_body["error"]

    post oauth_token_path, params: { grant_type: "authorization_code", client_id: client["client_id"], code:, redirect_uri: REDIRECT_URI, code_verifier: verifier }
    assert_response :success

    post oauth_token_path, params: { grant_type: "authorization_code", client_id: client["client_id"], code:, redirect_uri: REDIRECT_URI, code_verifier: verifier }
    assert_equal "invalid_grant", response.parsed_body["error"]
  end

  test "refresh tokens rotate and can be revoked from the admin" do
    tokens = authorize_and_get_tokens
    client_id = Oauth::Client.last.uid

    post oauth_token_path, params: { grant_type: "refresh_token", client_id:, refresh_token: tokens["refresh_token"] }
    refreshed = response.parsed_body
    assert refreshed["access_token"]

    post oauth_token_path, params: { grant_type: "refresh_token", client_id:, refresh_token: tokens["refresh_token"] }
    assert_equal "invalid_grant", response.parsed_body["error"]

    get connections_path
    assert_response :success
    delete connection_path(Oauth::Token.active.sole)
    mcp(refreshed["access_token"], initialize_request)
    assert_response :unauthorized
  end

  test "the consent screen requires signing in and can be denied" do
    client = register_client
    get oauth_authorization_path(authorization_params(client, "verifier"))
    assert_redirected_to new_session_path

    sign_in_as users(:one)
    get oauth_authorization_path(authorization_params(client, "verifier"))
    assert_response :success
    assert_select "button", "Autoriser"

    post oauth_authorization_path, params: authorization_params(client, "verifier").merge(decision: "deny")
    assert_match "error=access_denied", response.location
    assert_match "state=xyz", response.location

    get oauth_authorization_path(authorization_params(client, "verifier").merge(redirect_uri: "https://evil.example/cb"))
    assert_response :bad_request
  end

  private
    def initialize_request
      { jsonrpc: "2.0", id: 1, method: "initialize",
        params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "1" } } }
    end

    def mcp(token, payload)
      post mcp_path, params: payload, as: :json, headers: { "Authorization" => "Bearer #{token}", "Accept" => "application/json, text/event-stream" }
    end

    def call_tool(token, name, **arguments)
      mcp(token, { jsonrpc: "2.0", id: 3, method: "tools/call", params: { name:, arguments: } })
      assert_response :success
      response.parsed_body.fetch("result")
    end

    def issue_token(user = users(:one))
      Oauth::Token.issue!(client: Oauth::Client.create!(name: "Claude", redirect_uris: [ REDIRECT_URI ]), user:).access_token
    end

    def register_client
      post oauth_registration_path, params: { client_name: "Claude", redirect_uris: [ REDIRECT_URI ] }, as: :json
      assert_response :created
      response.parsed_body
    end

    def authorization_params(client, verifier)
      { client_id: client["client_id"], redirect_uri: REDIRECT_URI, response_type: "code", state: "xyz",
        code_challenge: Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(verifier), padding: false), code_challenge_method: "S256" }
    end

    def authorize_and_get_tokens
      client = register_client
      verifier = SecureRandom.urlsafe_base64(48)
      sign_in_as users(:one)
      post oauth_authorization_path, params: authorization_params(client, verifier).merge(decision: "approve")
      code = Rack::Utils.parse_query(URI.parse(response.location).query)["code"]
      post oauth_token_path, params: { grant_type: "authorization_code", client_id: client["client_id"], code:, redirect_uri: REDIRECT_URI, code_verifier: verifier }
      assert_response :success
      response.parsed_body
    end
end
