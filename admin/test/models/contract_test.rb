require "test_helper"

class ContractTest < ActiveSupport::TestCase
  test "a contract on a plan follows the catalogue price in effect" do
    contract = Contract.create!(client: clients(:dici), kinds: [ "maintenance" ], plan: plans(:evolution), label: "Maintenance", period: "annuel")
    assert_nil contract.amount
    assert_equal "mensuel", contract.period
    assert_equal 890, contract.amount_on(Date.new(2026, 12, 31))
    assert_equal 950, contract.amount_on(Date.new(2027, 1, 1))
    assert_equal 950, contract.next_plan_price.amount
  end

  test "a negotiated price overrides the catalogue" do
    contract = Contract.create!(client: clients(:dici), kinds: [ "maintenance" ], plan: plans(:evolution), label: "Maintenance", amount: 700, period: "mensuel")
    assert contract.negotiated?
    assert_equal 700, contract.amount_on(Date.new(2027, 6, 1))
    assert_nil contract.next_plan_price
  end

  test "a price is required without a plan" do
    assert_not Contract.new(client: clients(:dici), kinds: [ "hebergement" ], label: "Hébergement").valid?
  end

  test "revenue over the next year includes scheduled price changes" do
    contract = contracts(:maintenance)
    assert_equal 890 * 2 + 950 * 10, contract.revenue_over_next_year(Date.new(2026, 11, 1))
  end

  test "billing uses the price in effect on the due date" do
    contract = contracts(:maintenance)
    contract.update!(next_billing_on: Date.new(2027, 1, 1))
    invoice = contract.bill!(on: Date.new(2027, 1, 5))
    assert_equal 950, invoice.amount
    assert_equal Date.new(2027, 2, 1), contract.next_billing_on
  end

  test "a contract can cover several kinds" do
    contract = Contract.create!(client: clients(:dici), kinds: [ "", "maintenance", "hebergement" ], plan: plans(:essentiel), label: "Site Dici")
    assert_equal %w[ maintenance hebergement ], contract.kinds
    assert_equal "Maintenance + Hébergement", contract.kinds_label
    assert_equal 390, contract.current_amount
    assert_includes Contract.of_kind("maintenance"), contract
    assert_includes Contract.of_kind("hebergement"), contract
  end

  test "at least one known kind is required" do
    assert_not Contract.new(client: clients(:dici), kinds: [], label: "Vide").valid?
    assert_not Contract.new(client: clients(:dici), kinds: [ "inconnu" ], label: "Inconnu").valid?
  end

  test "margin" do
    contract = contracts(:hosting)
    assert_equal 36, contract.yearly_margin
    assert_equal 20.0, contract.margin_rate
  end

  test "billing prepares a draft invoice and moves the due date by one period" do
    contract = contracts(:hosting)
    assert contract.due?(Date.new(2026, 10, 24))

    invoice = assert_difference -> { Invoice.count } do
      contract.bill!(on: Date.new(2026, 10, 24))
    end

    assert_equal 180, invoice.amount
    assert invoice.draft?
    assert_nil invoice.number
    line = invoice.lines.sole
    assert_equal [ "year", Date.new(2026, 10, 1), Date.new(2027, 9, 30) ], [ line.unit, line.period_start, line.period_end ]
    assert_equal Date.new(2027, 10, 1), contract.reload.next_billing_on
    assert_equal Date.new(2026, 10, 24), contract.last_billed_on
  end
end
