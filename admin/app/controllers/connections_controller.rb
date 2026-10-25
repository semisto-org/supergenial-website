# Claude connections (OAuth tokens) of the signed-in user, revocable at any time.
class ConnectionsController < ApplicationController
  def index
    @tokens = Current.user.oauth_tokens.active.includes(:client).recent
  end

  def destroy
    token = Current.user.oauth_tokens.find(params[:id])
    token.revoke!
    AuditEvent.record!(action: "oauth.revoked", auditable: token.client, changeset: {})
    redirect_to connections_path, notice: "Connexion révoquée.", status: :see_other
  end
end
