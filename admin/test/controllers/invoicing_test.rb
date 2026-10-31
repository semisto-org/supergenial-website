require "test_helper"

class InvoicingTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  def create_draft
    post invoices_path, params: { invoice: { source: "admin", client_id: clients(:dici).id, label: "Refonte", issued_on: "2026-10-24", vat_regime: "standard",
                                             lines_attributes: { "0" => { description: "Design", quantity: "3", unit: "day", unit_price: "600", vat_rate: "21" },
                                                                 "1" => { description: "", unit_price: "" } } } }
    Invoice.last
  end

  test "draft, issue, pdf, credit note" do
    invoice = create_draft
    assert_redirected_to invoice_path(invoice)
    assert_equal [ 1800, 1 ], [ invoice.amount, invoice.lines.size ]

    [ invoice_path(invoice), edit_invoice_path(invoice), invoices_path, new_invoice_path, new_invoice_path(source: "okioki"),
      company_profile_path, edit_company_profile_path, root_path, client_path(clients(:dici)) ].each do |path|
      get path
      assert_response :success, path
    end

    post issue_invoice_path(invoice)
    assert_equal "2026-043", invoice.reload.number

    get edit_invoice_path(invoice)
    assert_redirected_to invoice_path(invoice)

    get pdf_invoice_path(invoice)
    assert_equal "application/pdf", response.media_type

    post credit_note_invoice_path(invoice)
    credit_note = Invoice.last
    assert credit_note.credit_note?
    assert_redirected_to edit_invoice_path(credit_note)
  end

  test "blank rows sent by the form keep their defaults and are ignored" do
    blank = { description: "", quantity: "1", unit: "unit", unit_price: "0.0", vat_rate: "21", _destroy: "false" }
    post invoices_path, params: { invoice: { source: "admin", client_id: clients(:dici).id, label: "Refonte", issued_on: "2026-10-24", vat_regime: "standard",
                                             lines_attributes: { "0" => { description: "Design", quantity: "2", unit: "day", unit_price: "500", vat_rate: "21" },
                                                                 "1" => blank, "1730380000000" => blank } } }
    invoice = Invoice.last
    assert_redirected_to invoice_path(invoice)
    assert_equal [ 1000, 1 ], [ invoice.amount, invoice.lines.size ]
  end

  test "a line removed in the form is destroyed, an emptied saved line is reported in French" do
    invoice = create_draft
    line = invoice.lines.first
    patch invoice_path(invoice), params: { invoice: { lines_attributes: { "0" => { id: line.id, description: "" } } } }
    assert_response :unprocessable_entity
    assert_match "Description de ligne doit être rempli(e)", response.body

    patch invoice_path(invoice), params: { invoice: { lines_attributes: { "0" => { id: line.id, _destroy: "1" },
                                                                          "1" => { description: "Conseil", quantity: "1", unit: "hour", unit_price: "90", vat_rate: "21" } } } }
    assert_redirected_to invoice_path(invoice)
    assert_equal [ "Conseil" ], invoice.reload.lines.map(&:description)
  end

  test "sending without Recommand configured explains what is missing" do
    invoice = create_draft
    invoice.issue!
    clients(:dici).update!(peppol_id: "0208:0888888888")
    post deliver_invoice_path(invoice)
    assert_redirected_to invoice_path(invoice)
    assert_match "Recommand", flash[:alert]
  end

  test "reference an OkiOki invoice" do
    post invoices_path, params: { invoice: { source: "okioki", client_id: clients(:dici).id, label: "Ancienne", number: "2026-010", issued_on: "2026-02-01", amount: "120" } }
    invoice = Invoice.find_by!(number: "2026-010")
    assert invoice.okioki? && invoice.issued?
  end

  test "the accountant cannot issue" do
    invoice = create_draft
    sign_in_as users(:accountant)
    post issue_invoice_path(invoice)
    assert invoice.reload.draft?
  end
end
