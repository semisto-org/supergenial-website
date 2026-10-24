# A client registered through dynamic client registration (RFC 7591), e.g. claude.ai.
# Public client: no secret, PKCE is mandatory.
class Oauth::Client < ApplicationRecord
  has_many :authorization_codes, foreign_key: :oauth_client_id, dependent: :delete_all, inverse_of: :client
  has_many :tokens, foreign_key: :oauth_client_id, dependent: :delete_all, inverse_of: :client

  validates :uid, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 100 }
  validate :redirect_uris_are_safe

  before_validation { self.uid ||= SecureRandom.uuid }

  def redirect_uri?(uri) = redirect_uris.include?(uri)

  def to_s = name

  private
    # https only, except loopback addresses for local clients (RFC 8252).
    def redirect_uris_are_safe
      uris = Array(redirect_uris)
      return errors.add(:redirect_uris, "must contain between 1 and 10 URIs") unless uris.size.between?(1, 10)

      uris.each do |value|
        uri = URI.parse(value.to_s)
        loopback = uri.scheme == "http" && %w[localhost 127.0.0.1 [::1]].include?(uri.host)
        errors.add(:redirect_uris, "contains an unsafe URI: #{value}") unless (uri.scheme == "https" || loopback) && uri.host.present? && uri.fragment.nil?
      rescue URI::InvalidURIError
        errors.add(:redirect_uris, "contains an invalid URI: #{value}")
      end
    end
end
