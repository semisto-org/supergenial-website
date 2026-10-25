# Collects the new purchase invoices: Peppol documents from Recommand and PDF attachments from the purchases mailbox.
class PurchaseInboxJob < ApplicationJob
  queue_as :default

  def perform
    collect { PeppolPurchaseImport.new.run } if Recommand::Client.configured?
    collect { EmailPurchaseImport.new.run } if Gmail::Client.configured?
  end

  private
    # One source failing must not stop the other.
    def collect
      yield
    rescue Recommand::Error, Gmail::Error => error
      Rails.error.report(error, handled: true)
    end
end
