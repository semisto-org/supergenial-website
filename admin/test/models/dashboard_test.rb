require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  setup { @dashboard = Dashboard.new(year: 2026) }

  test "fixed costs, current and forecast" do
    assert_equal 104, @dashboard.monthly_costs
    assert_equal 184, @dashboard.monthly_forecast_costs
  end

  test "margin is computed on forecast costs" do
    assert_equal 650, @dashboard.invoiced
    assert_equal 650 - 184 * 12, @dashboard.gross_margin
  end

  test "unbilled hours grouped by client" do
    row = @dashboard.unbilled_by_client.sole
    assert_equal clients(:dici), row[:client]
    assert_equal 3.5, row[:hours]
    assert_equal 300, row[:amount]
  end

  test "low packs" do
    assert_equal [ packs(:silvea_10h) ], @dashboard.low_packs
  end

  test "monthly fixed costs whose invoice did not arrive last month" do
    fixed_costs(:anthropic).update!(supplier: suppliers(:ai_company))
    fixed_costs(:hatchbox).update!(supplier: suppliers(:hoster))
    assert_equal [ fixed_costs(:anthropic) ], @dashboard.missing_purchase_invoices(Date.new(2026, 11, 3)).to_a
    assert_equal [ fixed_costs(:hatchbox) ], @dashboard.missing_purchase_invoices(Date.new(2026, 10, 3)).to_a
  end
end
