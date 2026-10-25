class AdminMcp::Invoices::GetInvoice < AdminMcp::Tool
  description "Full sales document: lines, VAT breakdown, totals, payment and Peppol delivery status, credit notes."
  read_only!
  input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])

  class << self
    private
      def perform(id:) = { invoice: AdminMcp::Serializer.invoice(find(Invoice, id), detail: true) }
  end
end
