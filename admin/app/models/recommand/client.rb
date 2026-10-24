require "net/http"

# Minimal client for the Recommand Peppol API (https://docs.recommand.eu).
# Runtime variables (Coolify): RECOMMAND_API_KEY, RECOMMAND_API_SECRET, RECOMMAND_COMPANY_ID,
# RECOMMAND_BASE_URL (optional). Playground and production differ only by their keys.
module Recommand
  class Client
    BASE_URL = "https://app.recommand.eu"
    REQUIRED_ENV = %w[ RECOMMAND_API_KEY RECOMMAND_API_SECRET RECOMMAND_COMPANY_ID ].freeze

    def self.configured?(env = ENV) = REQUIRED_ENV.all? { |name| env[name].present? }

    def initialize(env: ENV)
      @key, @secret, @company_id = env.fetch("RECOMMAND_API_KEY"), env.fetch("RECOMMAND_API_SECRET"), env.fetch("RECOMMAND_COMPANY_ID")
      @base_url = env.fetch("RECOMMAND_BASE_URL", BASE_URL)
    end

    # Builds the UBL document without sending it.
    def generate(payload) = post("/api/v1/#{@company_id}/generate", payload)

    def send_document(payload) = post("/api/v1/#{@company_id}/send", payload)

    # Whether a Peppol address (e.g. 0208:0123456789) can receive documents.
    def verify(peppol_address) = post("/api/v1/verify", { peppolAddress: peppol_address })

    private
      def post(path, body)
        uri = URI.join(@base_url, path)
        request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json", "Accept" => "application/json")
        request.basic_auth(@key, @secret)
        request.body = body.to_json
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 60) { |http| http.request(request) }
        parsed = JSON.parse(response.body.presence || "{}")
        raise Error, error_message(response, parsed) unless response.is_a?(Net::HTTPSuccess) && parsed["success"] != false
        parsed
      rescue JSON::ParserError
        raise Error, "Réponse illisible de Recommand (HTTP #{response&.code})"
      rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => error
        raise Error, "Recommand injoignable : #{error.message}"
      end

      def error_message(response, parsed)
        details = parsed["errors"] || parsed["error"] || parsed["message"]
        "Recommand a refusé la demande (HTTP #{response.code}) : #{details.is_a?(String) ? details : details.to_json}"
      end
  end
end
