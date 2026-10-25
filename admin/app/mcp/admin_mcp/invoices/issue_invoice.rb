class AdminMcp::Invoices::IssueInvoice < AdminMcp::Tool
  description "Issue a draft invoice or credit note: gives it its legal number, due date and structured reference. " \
              "An issued document can never be edited or deleted again, only corrected by a credit note. " \
              "Show the user the draft (get_invoice) and ask for confirmation first."
  writes!(destructive: true)
  input_schema(properties: { id: { type: "integer" }, issued_on: { type: "string", format: "date", description: "Defaults to today." } },
               required: [ "id" ])

  class << self
    private
      def perform(id:, issued_on: nil)
        invoice = find(Invoice, id)
        invoice.issue!(on: parse_date(issued_on, "issued_on") || Date.current)
        { invoice: AdminMcp::Serializer.invoice(invoice, detail: true) }
      end
  end
end
