require "test_helper"

class TaxProjectionTest < ActiveSupport::TestCase
  setup do
    travel_to Date.new(2026, 11, 5)
    # Clear the shared fixtures to reason on round, fictive figures.
    [ Contract, FixedCost, TimeEntry ].each { |model| model.update_all(active: false) if model.column_names.include?("active") }
    Contract.update_all(status: "termine")
    TimeEntry.where(status: "a_facturer").update_all(status: "offert")
    FixedCost.update_all(active: false)
    PurchaseInvoice.delete_all
    Invoice.delete_all
    Invoice.create!(client: clients(:dici), label: "Fictive", issued_on: "2026-06-01", amount: 150_000, status: "issued", source: "okioki", number: "2026-001")
    PurchaseInvoice.create!(supplier: suppliers(:hoster), expense_category: expense_categories(:restaurant), issued_on: "2026-05-01", amount: 1_000)
    PurchaseInvoice.create!(supplier: suppliers(:hoster), expense_category: expense_categories(:hosting), issued_on: "2026-05-02", amount: 9_310)
    @plan = FiscalPlan.create!(year: 2026, monthly_remuneration: 3_000)
  end

  def projection = TaxProjection.new(year: 2026, plan: @plan.reload)

  test "profit, deductible costs and the remuneration condition" do
    p = projection
    assert_equal 1, p.remaining_months
    assert_equal 150_000, p.revenue
    assert_equal 9_310 + 690, p.costs, "restaurant counts for 69 %"
    assert_equal 3_000, p.remuneration
    assert_equal 615, p.social_contributions
    assert_equal 150_000 - 10_000 - 3_000 - 615, p.taxable_profit
    assert_not p.reduced_rate?
    assert_equal (136_385 * 0.25).round(2), p.corporate_tax.to_f
    assert_equal 42_000, p.remuneration_needed, "45 000 € is reached before the profit"
    assert p.year_end_alert?
  end

  test "paying the needed remuneration keeps the reduced rate" do
    @plan.update!(year_end_remuneration: projection.remuneration_needed)
    p = projection
    assert p.reduced_rate?
    assert_equal 0, p.remuneration_needed
    assert_operator p.taxable_profit, :<, 100_000
    assert_equal (p.taxable_profit * 0.20).round(2), p.corporate_tax
  end

  test "advance payments from the bank" do
    CodaImport.new(CodaFixture.file).run
    BankTransaction.where("amount < 0").sole.update!(status: "ignored", category: "taxes", booked_on: "2026-10-03")
    p = projection
    assert_equal 242, p.advance_paid
    assert_equal Date.new(2026, 12, 20), p.next_advance_payment[:due_on]
    assert_equal (p.corporate_tax / 4).round(2) * 3 - 242, p.advance_shortfall
  end
end
