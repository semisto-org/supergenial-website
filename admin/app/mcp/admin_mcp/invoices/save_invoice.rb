class AdminMcp::Invoices::SaveInvoice < AdminMcp::Tool
  description "Create a draft invoice, or update one when id is given. While a document is a draft, everything can change; " \
              "lines, when given, replace all its lines. Once issued, only paid_on and notes can change (correct it " \
              "with create_credit_note). Totals and VAT are computed from the lines. vat_regime defaults to the one " \
              "suggested for the client (standard, intra_eu reverse charge, outside_eu)."
  writes!(idempotent: true)

  LINE = {
    type: "object",
    properties: {
      description: { type: "string" },
      quantity: { type: "number" },
      unit: { type: "string", enum: InvoiceLine::UNITS.keys },
      unit_price: { type: "number", description: "Excluding VAT." },
      vat_rate: { type: "number", enum: VatRegime::RATES },
      period_start: { type: "string", format: "date" },
      period_end: { type: "string", format: "date" }
    },
    required: %w[ description quantity unit_price ]
  }.freeze

  input_schema(properties: {
    id: { type: "integer", description: "Id of the invoice to update; omit to create a draft." },
    client_id: { type: "integer" },
    project_id: { type: [ "integer", "null" ] },
    label: { type: "string" },
    vat_regime: { type: "string", enum: VatRegime::REGIMES.keys },
    issued_on: { type: "string", format: "date", description: "Draft date; issue_invoice sets the final date." },
    lines: { type: "array", items: LINE, minItems: 1 },
    paid_on: { type: [ "string", "null" ], format: "date" },
    notes: { type: [ "string", "null" ] }
  })

  class << self
    private
      def perform(id: nil, lines: nil, **attributes)
        invoice = id ? find(Invoice, id) : Invoice.new(source: "admin", status: "draft", kind: "invoice", issued_on: Date.current)
        if invoice.new_record?
          raise ArgumentError, "client_id, label and lines are required to create an invoice" if attributes[:client_id].blank? || attributes[:label].blank? || lines.blank?
          invoice.client = find(Client, attributes[:client_id])
          invoice.vat_regime = VatRegime.suggest(invoice.client)
        end

        invoice.assign_attributes(attributes.slice(:client_id, :project_id, :label, :vat_regime, :issued_on, :paid_on, :notes))
        replace_lines(invoice, lines) if lines
        invoice.save!
        { invoice: AdminMcp::Serializer.invoice(invoice.reload, detail: true) }
      end

      def replace_lines(invoice, lines)
        invoice.lines.each(&:mark_for_destruction)
        lines.each_with_index do |line, index|
          invoice.lines.build({ unit: "unit", vat_rate: 21 }.merge(line.slice(*LINE[:properties].keys)).merge(position: index))
        end
      end
  end
end
