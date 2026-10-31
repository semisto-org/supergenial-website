require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  def draft(client: clients(:dici), lines: [ { description: "Développement", quantity: 2, unit: "hour", unit_price: 80, vat_rate: 21 } ], **attributes)
    Invoice.create!(client:, label: "Site", issued_on: Date.new(2026, 10, 24), vat_regime: VatRegime.suggest(client), lines_attributes: lines, **attributes)
  end

  test "totals come from the lines" do
    invoice = draft(lines: [ { description: "A", quantity: 2, unit_price: 80, vat_rate: 21 }, { description: "B", quantity: 1, unit_price: 100, vat_rate: 6 } ])
    assert_equal 260, invoice.amount
    assert_equal 39.6, invoice.vat_amount
    assert_equal 299.6, invoice.total
  end

  test "numbering continues after the last OkiOki number, shared with credit notes" do
    assert_equal "2026-043", InvoiceNumbering.next(2026)
    invoice = draft
    invoice.issue!(on: Date.new(2026, 10, 24))
    assert_equal "2026-043", invoice.number
    assert_equal Date.new(2026, 11, 23), invoice.due_on

    credit_note = invoice.build_credit_note
    credit_note.save!
    credit_note.issue!(on: Date.new(2026, 10, 25))
    assert_equal "2026-044", credit_note.number
    assert_equal(-160, credit_note.amount)
    assert_nil credit_note.due_on
    assert_equal "2027-001", InvoiceNumbering.next(2027)
  end

  test "structured communication has a valid modulo 97 check" do
    reference = InvoiceNumbering.structured_reference("2026-043")
    assert_match %r{\A\+\+\+\d{3}/\d{4}/\d{5}\+\+\+\z}, reference
    digits = reference.delete("^0-9")
    assert_equal digits[0, 10].to_i % 97, digits[10, 2].to_i
  end

  test "an issued invoice cannot change, be deleted or get new lines" do
    invoice = draft
    invoice.issue!
    assert_not invoice.update(label: "Autre")
    assert invoice.reload.update(paid_on: Date.current)
    assert_not invoice.lines.build(description: "Ajout", unit_price: 1).save
    assert_not invoice.destroy
    assert Invoice.exists?(invoice.id)
  end

  test "issuing needs a complete client address and the client VAT number for reverse charge" do
    client = Client.create!(name: "Sans adresse", country: "FR")
    invoice = draft(client:)
    assert_raises(ActiveRecord::RecordInvalid) { invoice.issue! }
    assert_match "adresse du client", invoice.errors.full_messages.to_sentence
  end

  test "regime follows the client country" do
    assert_equal "standard", VatRegime.suggest(clients(:dici))
    assert_equal "intra_eu", VatRegime.suggest(clients(:lux))
    assert_equal "outside_eu", VatRegime.suggest(Client.new(country: "US"))
    assert_equal "standard", VatRegime.suggest(Client.new(country: "FR"))
  end

  test "reverse charge lines carry no VAT and the legal mention" do
    invoice = draft(client: clients(:lux))
    invoice.issue!
    assert_equal 0, invoice.vat_amount
    document = PeppolDocument.new(invoice).to_h
    assert_equal "AE", document[:lines].first[:vat][:category]
    assert_equal "VATEX-EU-AE", document[:vat][:subtotals].first[:exemptionReasonCode]
    assert_match "Autoliquidation", document[:note]
  end

  test "peppol document of an invoice" do
    invoice = draft
    invoice.issue!(on: Date.new(2026, 10, 24))
    document = PeppolDocument.new(invoice, pdf: "%PDF-fake").to_h
    assert_equal "2026-043", document[:invoiceNumber]
    assert_equal({ name: "D'ici", vatNumber: "BE0888888888", enterpriseNumberScheme: "0208", enterpriseNumber: "0888888888",
                   street: "Rue de l'Exemple 2", city: "Namur", postalZone: "5000", country: "BE", email: clients(:dici).invoicing_email }.compact, document[:buyer])
    assert_equal "193.60", document[:totals][:taxInclusiveAmount]
    assert_equal invoice.structured_reference, document[:paymentMeans].first[:reference]
    assert_equal "pdf", document[:attachments].first[:id]
  end

  test "units take the French plural from two on" do
    assert_equal "an", InvoiceLine.new(unit: "year", quantity: 1.5).unit_label
    assert_equal "ans", InvoiceLine.new(unit: "year", quantity: 2).unit_label
    assert_equal "pièces", InvoiceLine.new(unit: "unit", quantity: 3).unit_label
    assert_equal "mois", InvoiceLine.new(unit: "month", quantity: 6).unit_label
    assert_equal "h", InvoiceLine.new(unit: "hour", quantity: 7.5).unit_label
  end

  test "pdf renders" do
    invoice = draft
    invoice.issue!
    assert InvoicePdf.new(invoice).render.start_with?("%PDF")
  end

  test "a draft pdf renders and announces what issuing will add instead of leaving blanks" do
    invoice = draft
    pdf = InvoicePdf.new(invoice)
    assert pdf.render.start_with?("%PDF")
    assert_match "seront attribués à l'émission", pdf.send(:payment_sentence)
    assert_nil pdf.send(:payment_qr)
  end

  test "an issued invoice pdf gives the due date, the structured communication and a payment QR code" do
    invoice = draft
    invoice.issue!(on: Date.new(2026, 10, 24))
    pdf = InvoicePdf.new(invoice)
    assert_match "avant le <b>23/11/2026</b>", pdf.send(:payment_sentence)
    assert_match "communication structurée", pdf.send(:payment_sentence)
    assert_kind_of RQRCode::QRCode, pdf.send(:payment_qr)
  end

  test "the general terms are printed on a page of their own, frozen with the seller at issuing" do
    CompanyProfile.current.update!(general_terms: "## 1. Objet\nUn paragraphe.\n\n## 2. Paiement\nÀ 30 jours.")
    invoice = draft
    invoice.issue!
    assert_equal "## 1. Objet\nUn paragraphe.\n\n## 2. Paiement\nÀ 30 jours.", invoice.seller["general_terms"]
    assert_equal [ [ :heading, "1. Objet" ], [ :paragraph, "Un paragraphe." ], [ :heading, "2. Paiement" ], [ :paragraph, "À 30 jours." ] ],
                 InvoicePdf.new(invoice).send(:terms_blocks)
  end

  test "the default general terms fit on one page" do
    invoice = draft
    pdf = InvoicePdf.new(invoice)
    assert pdf.send(:terms_blocks).any?
    assert InvoicePdf::TERMS_SIZES.any? { |size| pdf.send(:terms_fit?, pdf.send(:terms_blocks), size) }
  end

  test "an invoice issued before the general terms existed gets no terms page" do
    invoice = draft
    invoice.issue!
    invoice.update_column(:seller, invoice.seller.except("general_terms"))
    assert_empty InvoicePdf.new(invoice.reload).send(:terms_blocks)
  end

  test "a credit note pdf renders without payment details" do
    invoice = draft
    invoice.issue!
    credit_note = invoice.build_credit_note
    credit_note.save!
    credit_note.issue!
    assert InvoicePdf.new(credit_note).render.start_with?("%PDF")
  end
end
