require "net/http"
require "openssl"

# Minimal client for the Enable Banking API (https://enablebanking.com/docs/api/), the PSD2 aggregator that
# reads the company bank accounts. Every call is signed with a short-lived JWT (RS256) made from the
# application's private key. Runtime variables (Coolify): ENABLE_BANKING_APPLICATION_ID, ENABLE_BANKING_PRIVATE_KEY.
module EnableBanking
  class Error < StandardError; end

  class Client
    BASE_URL = "https://api.enablebanking.com"
    REQUIRED_ENV = %w[ ENABLE_BANKING_APPLICATION_ID ENABLE_BANKING_PRIVATE_KEY ].freeze

    def self.configured?(env = ENV) = REQUIRED_ENV.all? { |name| env[name].present? }

    def initialize(env: ENV)
      @application_id = env.fetch("ENABLE_BANKING_APPLICATION_ID")
      @key = OpenSSL::PKey::RSA.new(env.fetch("ENABLE_BANKING_PRIVATE_KEY").gsub("\\n", "\n"))
      @base_url = env.fetch("ENABLE_BANKING_BASE_URL", BASE_URL)
    end

    # Banks of a country, with how long a consent may last (maximum_consent_validity, in seconds).
    def aspsps(country) = get("/aspsps?country=#{CGI.escape(country)}").fetch("aspsps", [])

    # Starts the consent at the bank: returns the URL to send the user to.
    def start_authorization(aspsp_name:, country:, valid_until:, state:, redirect_url:, psu_type: "business")
      post("/auth", { access: { valid_until: valid_until.utc.iso8601 }, aspsp: { name: aspsp_name, country: }, state:,
                      redirect_url:, psu_type: }).fetch("url")
    end

    # Exchanges the code of the callback for a session and its accounts.
    def create_session(code) = post("/sessions", { code: })

    def delete_session(id) = perform(Net::HTTP::Delete, "/sessions/#{CGI.escape(id)}")

    # Booked transactions of an account since a date, all pages.
    def transactions(account_uid, date_from:)
      transactions, continuation_key = [], nil
      loop do
        query = { date_from: date_from.iso8601, transaction_status: "BOOK", continuation_key: }.compact.to_query
        page = get("/accounts/#{CGI.escape(account_uid)}/transactions?#{query}")
        transactions.concat(page.fetch("transactions", []))
        continuation_key = page["continuation_key"].presence
        break unless continuation_key
      end
      transactions
    end

    def token(now: Time.current)
      header = { typ: "JWT", alg: "RS256", kid: @application_id }
      claims = { iss: "enablebanking.com", aud: "api.enablebanking.com", iat: now.to_i, exp: now.to_i + 3600 }
      signing_input = [ header, claims ].map { |part| Base64.urlsafe_encode64(part.to_json, padding: false) }.join(".")
      "#{signing_input}.#{Base64.urlsafe_encode64(@key.sign(OpenSSL::Digest::SHA256.new, signing_input), padding: false)}"
    end

    private
      def get(path) = perform(Net::HTTP::Get, path)

      def post(path, body) = perform(Net::HTTP::Post, path, body)

      def perform(verb, path, body = nil)
        uri = URI.parse("#{@base_url}#{path}")
        request = verb.new(uri, "Content-Type" => "application/json", "Accept" => "application/json", "Authorization" => "Bearer #{token}")
        request.body = body.to_json if body
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 60) { |http| http.request(request) }
        parsed = JSON.parse(response.body.presence || "{}")
        raise Error, "Enable Banking a refusé la demande (HTTP #{response.code}) : #{parsed['message'] || parsed['error'] || parsed.to_json}" unless response.is_a?(Net::HTTPSuccess)
        parsed
      rescue JSON::ParserError
        raise Error, "Réponse illisible d'Enable Banking (HTTP #{response&.code})"
      rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => error
        raise Error, "Enable Banking injoignable : #{error.message}"
      end
  end
end
