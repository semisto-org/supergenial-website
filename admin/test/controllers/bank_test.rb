require "test_helper"

class BankTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  def upload = post(bank_statements_path, params: { file: Rack::Test::UploadedFile.new(StringIO.new(CodaFixture.file), "text/plain", original_filename: "belfius.cod") })

  test "import a CODA file and reconcile by hand" do
    assert_difference -> { BankTransaction.count }, 2 do
      upload
    end
    assert_redirected_to bank_transactions_path(status: "unmatched")
    statement = BankStatement.last

    [ bank_statements_path, bank_statement_path(statement), bank_transactions_path, bank_transactions_path(status: "unmatched"),
      bank_transaction_path(statement.transactions.first), bank_transaction_path(statement.transactions.last), root_path ].each do |path|
      get path
      assert_response :success, path
    end
    get file_bank_statement_path(statement)
    assert_equal CodaFixture.file, response.body

    payment, expense = statement.transactions
    invoice = Invoice.create!(client: clients(:dici), label: "Fictive", issued_on: "2026-09-01", amount: 121, status: "issued", source: "okioki", number: "2026-050")
    post match_bank_transaction_path(payment), params: { document_type: "Invoice", document_id: invoice.id }
    assert_redirected_to bank_transaction_path(expense)
    assert_equal Date.new(2026, 10, 2), invoice.reload.paid_on

    post ignore_bank_transaction_path(expense), params: { category: "bank_fees" }
    assert expense.reload.ignored?
  end

  test "a file that is not CODA is refused" do
    post bank_statements_path, params: { file: Rack::Test::UploadedFile.new(StringIO.new("Date;Montant\n"), "text/csv", original_filename: "export.csv") }
    assert_redirected_to bank_statements_path
    assert_match "Import impossible", flash[:alert]
  end

  test "the accountant reads the bank but cannot import or reconcile" do
    upload
    sign_in_as users(:accountant)
    transaction = BankTransaction.last
    get bank_transaction_path(transaction)
    assert_response :success
    post ignore_bank_transaction_path(transaction), params: { category: "other" }
    assert transaction.reload.unmatched?
    assert_no_difference -> { BankStatement.count } do
      upload
    end
  end
end
