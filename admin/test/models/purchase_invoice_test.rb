require "test_helper"

class PurchaseInvoiceTest < ActiveSupport::TestCase
  test "reverse charge: VAT is self-assessed and deducted" do
    purchase = purchase_invoices(:ai_september)
    assert purchase.reverse_charge?
    assert_equal [ 31.5, 31.5 ], [ purchase.self_assessed_vat, purchase.deductible_vat ]
    assert_equal [ "88", "55" ], purchase.regime.values_at(:base_grid, :due_grid)
  end

  test "the category gives the deductible VAT share" do
    purchase = purchase_invoices(:belgian_email)
    purchase.update!(expense_category: expense_categories(:restaurant))
    assert_equal 0, purchase.vat_deductible_percent
    assert_equal 0, purchase.deductible_vat
  end

  test "an invoice in another currency is converted to euros" do
    purchase = PurchaseInvoice.create!(currency: "usd", original_amount: 100, exchange_rate: 0.92)
    assert_equal [ "USD", 92 ], [ purchase.currency, purchase.amount ]
  end

  test "booking needs a supplier, a category, a number and a date" do
    purchase = PurchaseInvoice.create!
    assert_raises(ActiveRecord::RecordInvalid) { purchase.book! }
    assert purchase.errors.of_kind?(:supplier, :blank)
    purchase_invoices(:ai_september).book!
    assert purchase_invoices(:ai_september).booked?
  end

  test "a Belgian supplier must use Peppol" do
    assert purchase_invoices(:belgian_email).peppol_missing?
    assert_not purchase_invoices(:hosting_october).peppol_missing?
    assert PurchaseInvoice.new(seller_country: "BE").peppol_missing?
  end

  test "Claude's reading fills the blanks and finds the supplier" do
    purchase = PurchaseInvoice.new(number: "typed by hand")
    purchase.apply_extraction("document_type" => "invoice", "supplier_name" => "Hébergeur fictif", "supplier_country" => "CH",
                              "invoice_number" => "H-1", "issue_date" => "2026-10-03", "currency" => "EUR", "net_amount" => 50,
                              "vat_amount" => 0, "reverse_charge" => true)
    assert_equal [ suppliers(:hoster), expense_categories(:hosting) ], [ purchase.supplier, purchase.expense_category ]
    assert_equal [ "typed by hand", Date.new(2026, 10, 3), 50 ], [ purchase.number, purchase.issued_on, purchase.amount ]
    assert_equal "outside_eu_services", purchase.vat_regime
  end

  test "documents must be PDFs or images" do
    purchase = PurchaseInvoice.new
    purchase.document.attach(io: StringIO.new("MZ"), filename: "virus.exe", content_type: "application/x-msdownload")
    assert_not purchase.valid?
    assert purchase.errors.key?(:document)
  end
end
