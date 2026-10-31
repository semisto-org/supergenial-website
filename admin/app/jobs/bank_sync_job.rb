# Reads the new movements of the connected bank accounts (every morning in production).
class BankSyncJob < ApplicationJob
  queue_as :default

  def perform(connection = nil)
    return unless EnableBanking::Client.configured?
    Current.actor_kind = "system"
    connections = connection ? [ connection ] : BankConnection.active.to_a
    connections.each do |bank_connection|
      bank_connection.sync!
    rescue EnableBanking::Error => error
      Rails.error.report(error, handled: true, context: { bank_connection_id: bank_connection.id })
    end
  end
end
