# Turns an issued invoice or credit note into the JSON document the Recommand API converts to Peppol BIS 3 UBL.
class PeppolDocument
  def initialize(invoice, pdf: nil)
    @invoice, @pdf = invoice, pdf
  end

  def document_type = @invoice.credit_note? ? "creditNote" : "invoice"

  def to_h
    document = {
      issueDate: @invoice.issued_on.iso8601,
      note: [ @invoice.label, mention ].compact_blank.join("\n"),
      buyerReference: @invoice.project&.name,
      seller: party(@invoice.seller),
      buyer: party(@invoice.buyer),
      paymentMeans: payment_means,
      lines: lines,
      totals: totals,
      vat: vat,
      currency: "EUR"
    }
    if @invoice.credit_note?
      document[:creditNoteNumber] = @invoice.number
      document[:invoiceReferences] = [ { id: @invoice.credited_invoice.number, issueDate: @invoice.credited_invoice.issued_on.iso8601 } ]
    else
      document[:invoiceNumber] = @invoice.number
      document[:dueDate] = @invoice.due_on&.iso8601
      document[:paymentTerms] = { note: "Paiement à #{(@invoice.due_on - @invoice.issued_on).to_i} jours, communication #{@invoice.structured_reference}" } if @invoice.due_on
    end
    document[:attachments] = [ attachment ] if @pdf
    document.compact
  end

  private
    def mention = @invoice.regime[:mention]

    def party(data)
      data = data.to_h.stringify_keys
      vat = data["vat_number"].presence
      {
        name: data["legal_name"] || data["name"], vatNumber: vat,
        enterpriseNumberScheme: (vat&.start_with?("BE") ? "0208" : nil), enterpriseNumber: vat&.start_with?("BE") ? vat.delete_prefix("BE") : nil,
        street: data["street"], city: data["city"], postalZone: data["postal_code"], country: data["country"],
        email: data["email"].presence, phone: data["phone"].presence
      }.compact
    end

    def payment_means
      return [] unless @invoice.invoice?
      [ { paymentMethod: "credit_transfer", reference: @invoice.structured_reference, iban: @invoice.seller["iban"], financialInstitutionBranch: @invoice.seller["bic"].presence }.compact ]
    end

    def lines
      @invoice.lines.map.with_index(1) do |line, index|
        {
          id: index.to_s, name: line.description, quantity: decimal(line.quantity), unitCode: line.unit_code,
          netPriceAmount: decimal(line.unit_price), netAmount: decimal(line.net_amount),
          vat: { category: @invoice.vat_category, percentage: decimal(@invoice.standard? ? line.vat_rate : 0) },
          billingPeriod: (line.period_start && line.period_end ? { startDate: line.period_start.iso8601, endDate: line.period_end.iso8601 } : nil)
        }.compact
      end
    end

    def totals
      net = @invoice.subtotal
      { linesAmount: decimal(net), taxExclusiveAmount: decimal(net), taxInclusiveAmount: decimal(net + @invoice.vat_amount), payableAmount: decimal(net + @invoice.vat_amount) }
    end

    def vat
      subtotals = @invoice.vat_subtotals.map do |subtotal|
        { taxableAmount: decimal(subtotal[:taxable]), vatAmount: decimal(subtotal[:vat]), category: @invoice.vat_category, percentage: decimal(subtotal[:rate]),
          exemptionReasonCode: @invoice.regime[:vatex] }.compact
      end
      { totalVatAmount: decimal(@invoice.vat_amount), subtotals: }
    end

    def attachment
      { id: "pdf", mimeCode: "application/pdf", filename: "#{@invoice.number}.pdf", description: "Version lisible (PDF)", embeddedDocument: Base64.strict_encode64(@pdf) }
    end

    def decimal(value) = format("%.2f", value.to_d)
end
