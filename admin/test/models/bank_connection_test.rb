require "test_helper"

class BankConnectionTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :calls

    def initialize(transactions) = (@transactions, @calls = transactions, [])

    def transactions(uid, date_from:)
      @calls << [ uid, date_from ]
      @transactions
    end
  end

  SESSION = {
    "session_id" => "session-fictive", "access" => { "valid_until" => "2027-04-29T10:00:00Z" },
    "accounts" => [ { "uid" => "acc-1", "account_id" => { "iban" => "BE00 0000 0000 0000" }, "name" => "Compte fictif", "currency" => "EUR" } ]
  }.freeze

  def movement(reference, amount, indicator, **attributes)
    { "entry_reference" => reference, "transaction_amount" => { "amount" => amount, "currency" => "EUR" }, "credit_debit_indicator" => indicator,
      "booking_date" => "2026-10-20", "value_date" => "2026-10-20", "status" => "BOOK" }.merge(attributes.stringify_keys)
  end

  setup do
    @connection = BankConnection.create!(aspsp_name: "Belfius", country: "BE")
    @connection.activate!(SESSION)
  end

  test "activation keeps the session and the accounts" do
    assert @connection.active?
    assert_equal [ "BE00000000000000" ], @connection.ibans
    assert_equal Time.utc(2027, 4, 29, 10), @connection.valid_until
    assert @connection.state.present?
  end

  test "sync creates signed movements, reconciles them and does not duplicate" do
    client = FakeClient.new([
      movement("E1", "121.00", "CRDT", debtor: { "name" => "Client fictif" }, debtor_account: { "iban" => "BE11 1111 1111 1111" },
               remittance_information: [ "+++090/9337/55493+++" ]),
      movement("E2", "30.25", "DBIT", creditor: { "name" => "Outil fictif" }, remittance_information: [ "Abonnement", "octobre" ])
    ])
    assert_equal 2, @connection.sync!(client:, today: Date.new(2026, 10, 31))
    assert_equal [ [ "acc-1", Date.new(2026, 8, 3) ] ], client.calls

    credit = BankTransaction.find_by!(external_id: "E1")
    assert_equal [ 121, "Client fictif", "BE11111111111111", "090933755493", "BE00000000000000" ],
                 [ credit.amount, credit.counterparty_name, credit.counterparty_iban, credit.structured_reference, credit.account_iban ]
    debit = BankTransaction.find_by!(external_id: "E2")
    assert_equal [ -30.25.to_d, "Outil fictif", "Abonnement octobre" ], [ debit.amount, debit.counterparty_name, debit.communication ]

    assert_equal 0, @connection.sync!(client:)
    assert_equal Date.current - BankConnection::OVERLAP_DAYS, client.calls.last.last, "later reads overlap the previous one"
  end

  test "a movement already imported from a CODA statement is skipped" do
    statement = BankStatement.create!(iban: "BE00000000000000", number: 1, statement_on: Date.new(2026, 10, 20), opening_balance: 0, closing_balance: -30.25, digest: "fictive")
    statement.transactions.create!(sequence: 1, booked_on: Date.new(2026, 10, 20), amount: -30.25)
    assert_equal 0, @connection.sync!(client: FakeClient.new([ movement("E2", "30.25", "DBIT") ]))
  end

  test "an expired consent is not read and asks for renewal" do
    @connection.update!(valid_until: 1.day.ago)
    assert_equal 0, @connection.sync!(client: FakeClient.new([ movement("E1", "1", "CRDT") ]))
    assert @connection.reload.expired?
    assert_equal [ @connection ], BankConnection.to_renew

    renewed = BankConnection.create!(aspsp_name: "Belfius", country: "BE")
    renewed.activate!(SESSION.merge("access" => { "valid_until" => 170.days.from_now.iso8601 }))
    assert_empty BankConnection.to_renew
  end
end
