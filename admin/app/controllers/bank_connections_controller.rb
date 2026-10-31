# Connects the company bank accounts through Enable Banking (PSD2): consent at the bank, then a daily read.
class BankConnectionsController < ApplicationController
  require_admin

  def index
    @configured = EnableBanking::Client.configured?
    @bank_connections = BankConnection.recent
  end

  def create
    return redirect_to(bank_connections_path, alert: "Enable Banking n'est pas configuré (variables ENABLE_BANKING_* dans Coolify).") unless EnableBanking::Client.configured?

    client = EnableBanking::Client.new
    connection = BankConnection.create!(aspsp_name: params[:aspsp_name].presence || BankConnection::DEFAULT_BANK, country: "BE",
                                        psu_type: params[:psu_type].presence_in(BankConnection::PSU_TYPES.keys) || "business")
    validity = client.aspsps(connection.country).find { |aspsp| aspsp["name"] == connection.aspsp_name }&.dig("maximum_consent_validity") || 90.days.to_i
    connection.update!(valid_until: Time.current + validity.to_i.seconds - 1.hour)
    url = client.start_authorization(aspsp_name: connection.aspsp_name, country: connection.country, valid_until: connection.valid_until,
                                     state: connection.state, redirect_url: callback_bank_connections_url, psu_type: connection.psu_type)
    raise EnableBanking::Error, "Adresse de la banque inattendue" unless URI.parse(url).is_a?(URI::HTTPS)
    # The bank's consent page, given by Enable Banking (not by the request).
    redirect_to url, allow_other_host: true
  rescue EnableBanking::Error => error
    connection&.update(last_error: error.message)
    redirect_to bank_connections_path, alert: error.message
  end

  # The bank sends the user back here with a code (or an error) once the consent is given.
  def callback
    connection = BankConnection.pending.find_by(state: params[:state].to_s)
    return redirect_to(bank_connections_path, alert: "Connexion inconnue ou déjà terminée : recommence.") unless connection
    if params[:code].blank?
      connection.update!(last_error: params[:error_description].presence || params[:error].presence || "Accord refusé à la banque")
      return redirect_to(bank_connections_path, alert: "La banque n'a pas donné son accord : #{connection.last_error}")
    end

    connection.activate!(EnableBanking::Client.new.create_session(params[:code]))
    BankSyncJob.perform_later(connection)
    redirect_to bank_connections_path, notice: "Comptes connectés : les mouvements arrivent dans quelques instants."
  rescue EnableBanking::Error => error
    connection&.update(last_error: error.message)
    redirect_to bank_connections_path, alert: error.message
  end

  def sync
    connection = BankConnection.find(params[:id])
    added = connection.sync!
    redirect_to bank_connections_path, notice: "#{added} nouveau(x) mouvement(s)."
  rescue EnableBanking::Error => error
    redirect_to bank_connections_path, alert: error.message
  end

  def destroy
    connection = BankConnection.find(params[:id])
    begin
      EnableBanking::Client.new.delete_session(connection.session_id) if connection.session_id && EnableBanking::Client.configured?
    rescue EnableBanking::Error => error
      Rails.error.report(error, handled: true)
    end
    connection.destroy!
    redirect_to bank_connections_path, notice: "Connexion supprimée (les mouvements déjà lus restent)."
  end
end
