require "net/http"

# Minimal client for the Recommand Peppol API (https://docs.recommand.eu).
# Runtime variables (Coolify): RECOMMAND_API_KEY, RECOMMAND_API_SECRET (or RECOMMAND_SECRET),
# RECOMMAND_COMPANY_ID, RECOMMAND_BASE_URL (optional). Playground and production differ only by their keys.
module Recommand
  class Client
    BASE_URL = "https://app.recommand.eu"
    # Each setting with the variable names it may be stored under, preferred name first.
    SETTINGS = {
      key: %w[ RECOMMAND_API_KEY ],
      secret: %w[ RECOMMAND_API_SECRET RECOMMAND_SECRET ],
      company_id: %w[ RECOMMAND_COMPANY_ID ]
    }.freeze

    def self.configured?(env = ENV) = missing_env(env).empty?

    # Preferred names of the settings that are not set.
    def self.missing_env(env = ENV) = SETTINGS.values.reject { |names| lookup(env, names) }.map(&:first)

    def self.lookup(env, names) = names.lazy.map { |name| env[name].presence }.find(&:itself)

    def initialize(env: ENV)
      missing = self.class.missing_env(env)
      raise KeyError, "Missing #{missing.join(", ")}" if missing.any?

      @key, @secret, @company_id = SETTINGS.values.map { |names| self.class.lookup(env, names) }
      @base_url = env.fetch("RECOMMAND_BASE_URL", BASE_URL)
    end

    # Builds the UBL document without sending it.
    def generate(payload) = post("/api/v1/#{@company_id}/generate", payload)

    def send_document(payload) = post("/api/v1/#{@company_id}/send", payload)

    # Whether a Peppol address (e.g. 0208:0123456789) can receive documents.
    def verify(peppol_address) = post("/api/v1/verify", { peppolAddress: peppol_address })

    # Received documents not marked as read yet.
    def inbox = get("/api/v1/inbox?companyId=#{CGI.escape(@company_id)}").fetch("documents", [])

    # One document with its UBL (xml) and its parsed content (same shape as the documents we send).
    def document(id) = get("/api/v1/documents/#{CGI.escape(id)}").fetch("document")

    def mark_as_read(id) = post("/api/v1/documents/#{CGI.escape(id)}/mark-as-read", {})

    private
      def get(path) = perform(Net::HTTP::Get, path)

      def post(path, body) = perform(Net::HTTP::Post, path, body)

      def perform(verb, path, body = nil)
        uri = URI.join(@base_url, path)
        request = verb.new(uri, "Content-Type" => "application/json", "Accept" => "application/json")
        request.basic_auth(@key, @secret)
        request.body = body.to_json if body
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
