# Consent screen. Signing in goes through the regular admin login,
# so any login protection (2FA…) also protects MCP access.
class Oauth::AuthorizationsController < ApplicationController
  layout "session"

  before_action :set_request_params

  def new
    @client = Oauth::Client.find_by(uid: @params[:client_id])
    return render_invalid("Application inconnue.") unless @client
    return render_invalid("Adresse de retour non autorisée.") unless @client.redirect_uri?(@params[:redirect_uri])

    error = request_error
    redirect_with(error:) if error
  end

  def create
    @client = Oauth::Client.find_by(uid: @params[:client_id])
    return render_invalid("Application inconnue.") unless @client&.redirect_uri?(@params[:redirect_uri])
    return redirect_with(error: request_error) if request_error
    return redirect_with(error: "access_denied") unless params[:decision] == "approve"

    code = @client.authorization_codes.create!(user: Current.user, redirect_uri: @params[:redirect_uri],
                                               code_challenge: @params[:code_challenge], resource: @params[:resource])
    AuditEvent.record!(action: "oauth.authorized", auditable: @client, changeset: { redirect_uri: [ nil, @params[:redirect_uri] ] })
    redirect_with(code: code.code)
  end

  private
    def set_request_params
      @params = params.permit(:client_id, :redirect_uri, :response_type, :code_challenge, :code_challenge_method, :state, :scope, :resource)
    end

    def request_error
      if @params[:response_type] != "code"
        "unsupported_response_type"
      elsif @params[:code_challenge].blank? || @params[:code_challenge_method] != "S256"
        "invalid_request"
      end
    end

    # Errors that must not be sent to an unverified redirect URI are shown here instead.
    def render_invalid(message)
      @message = message
      render :invalid, status: :bad_request
    end

    def redirect_with(**query)
      uri = URI.parse(@params[:redirect_uri])
      query = URI.decode_www_form(uri.query.to_s) + query.compact.to_a
      query << [ "state", @params[:state] ] if @params[:state].present?
      query << [ "iss", request.base_url ]
      uri.query = URI.encode_www_form(query)
      redirect_to uri.to_s, allow_other_host: true
    end
end
