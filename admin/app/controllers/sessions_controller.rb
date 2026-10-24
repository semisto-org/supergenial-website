class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  allow_without_two_factor only: :destroy
  allow_read_only_writes only: %i[ create destroy ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Trop de tentatives, réessaie dans quelques minutes." }

  layout "session"

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      if user.two_factor_enabled?
        start_two_factor_challenge_for user
        redirect_to new_two_factor_path
      else
        start_new_session_for user
        redirect_to two_factor_setup_path
      end
    else
      redirect_to new_session_path, alert: "E-mail ou mot de passe incorrect."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
