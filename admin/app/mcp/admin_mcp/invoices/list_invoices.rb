class AdminMcp::Invoices::ListInvoices < AdminMcp::Tool
  description "List sales documents (invoices and credit notes), most recent first: drafts and issued documents made " \
              "in the admin, plus documents imported from OkiOki and Harvest. Amounts of credit notes are negative."
  read_only!
  input_schema(properties: {
    client_id: { type: "integer" },
    project_id: { type: "integer" },
    year: { type: "integer" },
    kind: { type: "string", enum: Invoice::KINDS.keys },
    status: { type: "string", enum: Invoice::STATUSES.keys },
    source: { type: "string", enum: Invoice::SOURCES.keys },
    unpaid_only: { type: "boolean", description: "Issued documents without a payment date." },
    number: { type: "string" },
    limit: { type: "integer", minimum: 1, maximum: 500, description: "Defaults to 100." }
  })

  class << self
    private
      def perform(client_id: nil, project_id: nil, year: nil, kind: nil, status: nil, source: nil, unpaid_only: false, number: nil, limit: 100)
        invoices = Invoice.recent.includes(:client)
        invoices = invoices.where({ client_id:, project_id:, kind:, status:, source:, number: }.compact)
        invoices = invoices.in_year(year) if year
        invoices = invoices.unpaid if unpaid_only
        invoices = invoices.limit(limit).to_a
        { invoices: invoices.map { |invoice| AdminMcp::Serializer.invoice(invoice) },
          total_excl_vat: AdminMcp::Serializer.money(invoices.sum(&:amount)) }
      end
  end
end
