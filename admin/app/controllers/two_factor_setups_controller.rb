require "rqrcode"

# Mandatory two-factor setup, shown after the first login with a password.
class TwoFactorSetupsController < ApplicationController
  allow_without_two_factor
  allow_read_only_writes
  before_action :redirect_if_enabled
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to two_factor_setup_path, alert: "Trop de tentatives, réessaie dans quelques minutes." }

  layout "session"

  def show
    session[:otp_setup_secret] ||= ROTP::Base32.random
    @secret = session[:otp_setup_secret]
    svg = RQRCode::QRCode.new(Current.user.provisioning_uri(@secret)).as_svg(module_size: 4, use_path: true, viewbox: true)
    @qr_code_src = "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end

  def create
    if Current.user.enable_two_factor!(session[:otp_setup_secret], params[:code])
      session.delete(:otp_setup_secret)
      redirect_to after_authentication_url, notice: "Double authentification activée."
    else
      redirect_to two_factor_setup_path, alert: "Code incorrect : vérifie l'heure du téléphone et réessaie."
    end
  end

  private
    def redirect_if_enabled
      redirect_to root_path if Current.user.two_factor_enabled?
    end
end
