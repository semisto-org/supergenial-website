require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "the group country decides the zone" do
    assert_equal "us", suppliers(:ai_company).zone
    assert_equal "other", suppliers(:hoster).zone
    assert_equal "be", suppliers(:belgian).zone
  end

  test "belgian suppliers are expected on Peppol" do
    assert suppliers(:belgian).peppol_expected?
    assert_not suppliers(:hoster).peppol_expected?
  end

  test "normalizes identifiers" do
    supplier = Supplier.create!(name: "X", billing_country: "be", vat_number: "be 0123.456.789", iban: "be68 5390 0754 7034")
    assert_equal [ "BE", "BE0123456789", "BE68539007547034" ], [ supplier.billing_country, supplier.vat_number, supplier.iban ]
  end
end
