# Short-lived, single-use code exchanged for tokens at /oauth/token, bound to a PKCE challenge.
class Oauth::AuthorizationCode < ApplicationRecord
  TTL = 10.minutes

  # Issued and rotated every hour: the audit log records consents and revocations instead.
  skip_audit

  belongs_to :client, class_name: "Oauth::Client", foreign_key: :oauth_client_id, inverse_of: :authorization_codes
  belongs_to :user

  attr_reader :code

  validates :redirect_uri, :code_challenge, presence: true

  before_validation on: :create do
    @code = Oauth.generate_secret("sgc")
    self.code_digest = Oauth.digest(@code)
    self.expires_at ||= TTL.from_now
  end

  def self.find_by_code(code)
    find_by(code_digest: Oauth.digest(code)) if code.present?
  end

  def usable? = used_at.nil? && expires_at.future?

  # PKCE with S256 only (OAuth 2.1).
  def verifier_matches?(verifier)
    return false if verifier.blank?
    computed = Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(verifier), padding: false)
    ActiveSupport::SecurityUtils.secure_compare(computed, code_challenge)
  end

  # Marks the code as used and issues tokens, or returns nil if it was already used (replay).
  def redeem!
    with_lock do
      return unless usable?
      update!(used_at: Time.current)
      Oauth::Token.issue!(client:, user:)
    end
  end
end
