module Authentication
  extend ActiveSupport::Concern

  PENDING_TWO_FACTOR_LIFETIME = 5.minutes

  included do
    before_action :require_authentication
    before_action :require_two_factor_setup
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_two_factor_setup, **options
    end

    def allow_without_two_factor(**options)
      skip_before_action :require_two_factor_setup, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    # Two-factor authentication is mandatory: a user without it is sent to the setup page.
    def require_two_factor_setup
      redirect_to two_factor_setup_path unless Current.user&.two_factor_enabled?
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.alive.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    # Password checked, second factor still to come.
    def start_two_factor_challenge_for(user)
      session[:pending_two_factor] = { "user_id" => user.id, "expires_at" => PENDING_TWO_FACTOR_LIFETIME.from_now.to_i }
    end

    def pending_two_factor_user
      pending = session[:pending_two_factor]
      User.find_by(id: pending["user_id"]) if pending && pending["expires_at"].to_i > Time.current.to_i
    end

    def start_new_session_for(user)
      session.delete(:pending_two_factor)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed[:session_id] = { value: session.id, expires: Session::LIFETIME, httponly: true, same_site: :lax, secure: Rails.env.production? }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
