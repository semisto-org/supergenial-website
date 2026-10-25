require "net/http"

# Minimal Gmail API client for the purchases mailbox, with an OAuth refresh token (scope gmail.modify).
# Runtime variables (Coolify): GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, GMAIL_REFRESH_TOKEN, GMAIL_USER (optional).
module Gmail
  class Client
    API = "https://gmail.googleapis.com/gmail/v1/users/"
    TOKEN_URL = "https://oauth2.googleapis.com/token"
    DEFAULT_USER = "sg-invoices@semisto.org"
    REQUIRED_ENV = %w[ GMAIL_CLIENT_ID GMAIL_CLIENT_SECRET GMAIL_REFRESH_TOKEN ].freeze

    def self.configured?(env = ENV) = REQUIRED_ENV.all? { |name| env[name].present? }

    def initialize(env: ENV)
      @env = env
      @user = env.fetch("GMAIL_USER", DEFAULT_USER)
    end

    def message_ids(query) = get("messages?#{URI.encode_www_form(q: query, maxResults: 100)}").fetch("messages", []).map { |message| message["id"] }

    def message(id) = get("messages/#{id}?format=full")

    def attachment(message_id, attachment_id) = Base64.urlsafe_decode64(get("messages/#{message_id}/attachments/#{attachment_id}").fetch("data"))

    def label_id(name)
      existing = get("labels").fetch("labels", []).find { |label| label["name"] == name }
      (existing || post("labels", { name:, labelListVisibility: "labelShow", messageListVisibility: "show" })).fetch("id")
    end

    def add_label(message_id, label_id) = post("messages/#{message_id}/modify", { addLabelIds: [ label_id ] })

    private
      def get(path) = perform(Net::HTTP::Get, path)

      def post(path, body) = perform(Net::HTTP::Post, path, body)

      def perform(verb, path, body = nil)
        uri = URI("#{API}#{CGI.escape(@user)}/#{path}")
        request = verb.new(uri, "Authorization" => "Bearer #{access_token}", "Content-Type" => "application/json")
        request.body = body.to_json if body
        parse(Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60) { |http| http.request(request) })
      rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => error
        raise Error, "Gmail injoignable : #{error.message}"
      end

      def access_token
        @access_token ||= begin
          response = Net::HTTP.post_form(URI(TOKEN_URL), client_id: @env.fetch("GMAIL_CLIENT_ID"), client_secret: @env.fetch("GMAIL_CLIENT_SECRET"),
                                                         refresh_token: @env.fetch("GMAIL_REFRESH_TOKEN"), grant_type: "refresh_token")
          parse(response).fetch("access_token")
        end
      end

      def parse(response)
        parsed = JSON.parse(response.body.presence || "{}")
        raise Error, "Gmail a refusé la demande (HTTP #{response.code}) : #{parsed['error'].to_json}" unless response.is_a?(Net::HTTPSuccess)
        parsed
      rescue JSON::ParserError
        raise Error, "Réponse illisible de Gmail (HTTP #{response.code})"
      end
  end
end
