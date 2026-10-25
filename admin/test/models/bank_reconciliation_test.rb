require "test_helper"

class BankReconciliationTest < ActiveSupport::TestCase
  setup do
    @invoice = Invoice.create!(client: clients(:dici), label: "Maintenance", issued_on: "2026-09-30", amount: 100, vat_amount: 21,
                               status: "issued", source: "okioki", number: "2026-043")
    @invoice.update_columns(structured_reference: "+++202/6000/04397+++")
    @purchase = PurchaseInvoice.create!(supplier: suppliers(:belgian), number: "2026-0042", issued_on: "2026-09-28", amount: 200, vat_amount: 42)
  end

  def import = CodaImport.new(CodaFixture.file, filename: "belfius.cod").run

  test "import creates the statement and reconciles what it can" do
    result = import
    statement = result.statements.sole
    assert_equal 2, result.matched
    assert statement.balanced?
    assert statement.file.attached?

    payment, expense = statement.transactions
    assert_equal @invoice, payment.invoice
    assert_equal Date.new(2026, 10, 2), @invoice.reload.paid_on
    assert_equal @purchase, expense.purchase_invoice
    assert_equal Date.new(2026, 10, 3), @purchase.reload.paid_on

    assert_equal 1, import.skipped, "the same statement is not imported twice"
  end

  test "manual reconciliation, undo and movements without document" do
    @invoice.update_columns(structured_reference: nil)
    @purchase.update!(number: "autre")
    payment, expense = import.statements.sole.transactions
    assert payment.unmatched?
    assert_equal @invoice, payment.candidates.first
    assert_equal @purchase, expense.candidates.first

    payment.match!(@invoice)
    assert @invoice.reload.paid?
    payment.unmatch!
    assert_not @invoice.reload.paid?

    assert_raises(ActiveRecord::RecordInvalid) { expense.ignore!(nil) }
    expense.ignore!("bank_fees")
    assert expense.reload.ignored?
  end
end
