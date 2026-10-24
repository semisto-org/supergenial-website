require "test_helper"

class SupplierDependenceTest < ActiveSupport::TestCase
  test "spending by zone follows the supplier's group" do
    dependence = SupplierDependence.new(today: Date.new(2026, 10, 24))
    totals = dependence.by_zone
    assert_equal [ 100, 150, 50 ], totals.values_at("be", "us", "other")
    assert_equal 50.0, dependence.share("us")
    assert_equal [ "T1 2026", "T2 2026", "T3 2026", "T4 2026" ], dependence.quarters.map { |quarter| quarter[:label] }
    assert_equal 100.0, dependence.quarters.third[:us_share]
    assert_equal suppliers(:ai_company), dependence.top_suppliers("us").sole[:supplier]
  end

  test "credit notes reduce the spending" do
    purchase_invoices(:belgian_email).update!(kind: "credit_note")
    assert_equal(-100, SupplierDependence.new(today: Date.new(2026, 10, 24)).by_zone["be"])
  end
end
