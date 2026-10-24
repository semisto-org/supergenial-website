# Remote MCP server (Streamable HTTP, stateless, JSON responses only).
# Every request carries an OAuth access token issued by Oauth::TokensController.
class McpController < ActionController::API
  before_action :authenticate

  def create
    response_json = AdminMcp.server(user: @token.user).handle_json(request.raw_post)
    response_json ? render(json: response_json) : head(:accepted)
  end

  # No server-initiated stream and no session to close in stateless mode.
  def unsupported
    response.set_header("Allow", "POST")
    head :method_not_allowed
  end

  private
    def authenticate
      @token = Oauth::Token.authenticate(bearer_token)
      if @token
        @token.touch_last_used
      else
        response.set_header("WWW-Authenticate", %(Bearer resource_metadata="#{oauth_protected_resource_url}"))
        render json: { error: "invalid_token" }, status: :unauthorized
      end
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/, 1]
    end
end
