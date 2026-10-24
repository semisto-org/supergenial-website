class ApplicationController < ActionController::Base
  include Authentication
  include ReadOnlyAccess
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action { Current.request_id = request.request_id }

  private
    # Pré-remplit le client quand on crée depuis sa fiche (?client_id=…).
    def preselected_client_id = params[:client_id].presence
end
