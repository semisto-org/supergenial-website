# OAuth 2.1 authorization server used by the MCP endpoint (claude.ai connectors).
# Secrets (codes, tokens) are never stored: only their SHA-256 digest.
module Oauth
  def self.table_name_prefix = "oauth_"

  def self.generate_secret(prefix) = "#{prefix}_#{SecureRandom.urlsafe_base64(32)}"

  def self.digest(secret) = OpenSSL::Digest::SHA256.hexdigest(secret.to_s)
end
