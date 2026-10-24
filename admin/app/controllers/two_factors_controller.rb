# Second login step: the six-digit code of the authenticator app.
class TwoFactorsController < ApplicationController
  allow_unauthenticated_access
  allow_read_only_writes
  before_action :set_pending_user
  rate_limit to: 5, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Trop de tentatives, réessaie dans quelques minutes." }

  layout "session"

  def new
  end

  def create
    if @user.verify_otp(params[:code])
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      redirect_to new_two_factor_path, alert: "Code incorrect ou déjà utilisé."
    end
  end

  private
    def set_pending_user
      @user = pending_two_factor_user or redirect_to(new_session_path, alert: "Reconnecte-toi.")
    end
end
