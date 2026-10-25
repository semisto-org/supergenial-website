class AdminMcp::Invoices::SendInvoice < AdminMcp::Tool
  description "Send an issued invoice or credit note to the client through Recommand: over Peppol when the client is " \
              "reachable, otherwise by e-mail to its billing address (never by e-mail for a Belgian business). " \
              "This writes to the client: ask for confirmation first."
  annotations(read_only_hint: false, destructive_hint: true, idempotent_hint: false, open_world_hint: true)
  input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])

  class << self
    private
      def perform(id:)
        invoice = find(Invoice, id)
        response = InvoiceDelivery.new(invoice).deliver!
        { invoice: AdminMcp::Serializer.invoice(invoice.reload), sent_over_peppol: response["sentOverPeppol"],
          email_recipients: Array(response["emailRecipients"]) }
      rescue InvoiceDelivery::Refused, Recommand::Error => error
        raise ArgumentError, error.message
      rescue KeyError
        raise ArgumentError, "Recommand is not configured (RECOMMAND_* variables in Coolify)."
      end
  end
end
