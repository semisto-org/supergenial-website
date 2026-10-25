class AdminMcp::Invoices::CreateCreditNote < AdminMcp::Tool
  description "Create a draft credit note copying the lines of an issued invoice. Adjust its lines with save_invoice " \
              "(e.g. to credit part of it), then issue it with issue_invoice."
  writes!
  input_schema(properties: { invoice_id: { type: "integer" } }, required: [ "invoice_id" ])

  class << self
    private
      def perform(invoice_id:)
        invoice = find(Invoice, invoice_id)
        raise ArgumentError, "Only an issued invoice made in the admin can be credited." unless invoice.invoice? && invoice.admin? && invoice.issued?
        credit_note = invoice.build_credit_note
        credit_note.save!
        { credit_note: AdminMcp::Serializer.invoice(credit_note, detail: true) }
      end
  end
end
