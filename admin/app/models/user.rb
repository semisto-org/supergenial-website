class User < ApplicationRecord
  include Choices

  OTP_ISSUER = "Admin Super Génial"

  has_secure_password
  has_many :sessions, dependent: :destroy

  # admin: full access. accountant: reads everything, comments, and closes VAT periods.
  choices :role, admin: "Administrateur", accountant: "Comptable"

  encrypts :otp_secret

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  def can_write? = admin?

  def display_name = name.presence || email_address

  def to_s = display_name

  def two_factor_enabled? = otp_enabled_at.present? && otp_secret.present?

  # Accepts each code once (replays are refused) with 30 seconds of clock drift.
  def verify_otp(code, secret: otp_secret)
    return false if secret.blank? || code.blank?
    timestamp = ROTP::TOTP.new(secret, issuer: OTP_ISSUER).verify(code.to_s.gsub(/\s/, ""), drift_behind: 30, after: otp_last_used_at)
    timestamp.present? && update_columns(otp_last_used_at: timestamp)
  end

  def enable_two_factor!(secret, code)
    return false unless verify_otp(code, secret:)
    update!(otp_secret: secret, otp_enabled_at: Time.current)
  end

  def reset_two_factor!
    update!(otp_secret: nil, otp_enabled_at: nil, otp_last_used_at: nil)
    sessions.destroy_all
  end

  def provisioning_uri(secret) = ROTP::TOTP.new(secret, issuer: OTP_ISSUER).provisioning_uri(email_address)
end
