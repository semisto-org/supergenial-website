require "test_helper"

class BankConnectionsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the page explains the missing configuration" do
    get bank_connections_path
    assert_response :success
    assert_match "ENABLE_BANKING_APPLICATION_ID", response.body
  end

  test "a refused consent is reported" do
    connection = BankConnection.create!(aspsp_name: "Belfius", country: "BE")
    get callback_bank_connections_path(state: connection.state, error: "access_denied")
    assert_redirected_to bank_connections_path
    assert_equal "access_denied", connection.reload.last_error
    assert connection.pending?
  end

  test "an unknown state is refused" do
    get callback_bank_connections_path(state: "inconnu", code: "x")
    assert_redirected_to bank_connections_path
    assert_match "inconnue", flash[:alert]
  end

  test "deleting keeps the movements" do
    connection = BankConnection.create!(aspsp_name: "Belfius", country: "BE")
    transaction = connection.bank_transactions.create!(booked_on: Date.current, amount: 10, external_id: "E1", account_iban: "BE00")
    delete bank_connection_path(connection)
    assert_redirected_to bank_connections_path
    assert_nil transaction.reload.bank_connection_id
  end

  test "the accountant cannot connect a bank" do
    sign_in_as users(:accountant)
    get bank_connections_path
    assert_redirected_to root_path
  end
end
