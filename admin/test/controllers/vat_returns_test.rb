require "test_helper"

class VatReturnsTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Date.new(2026, 10, 24)
    sign_in_as users(:one)
  end

  test "VAT pages and files" do
    [ vat_returns_path, vat_return_path("2026-3"), vat_return_path("2026-4"), company_profile_path, edit_company_profile_path, root_path ].each do |path|
      get path
      assert_response :success, path
    end
    get declaration_vat_return_path("2026-3")
    assert_match "VATConsignment", response.body
    get export_vat_return_path("2026-3")
    assert_equal "application/zip", response.media_type
    get vat_return_path("2026-9")
    assert_response :not_found
  end

  test "the accountant closes the quarter" do
    purchase_invoices(:ai_september).book!
    sign_in_as users(:accountant)
    assert_difference -> { VatPeriod.count } do
      post close_vat_return_path("2026-3")
    end
    assert_redirected_to vat_return_path("2026-3")
    get vat_return_path("2026-3")
    assert_select ".badge", text: "clôturé"

    assert_no_difference -> { VatPeriod.count } do
      post close_vat_return_path("2026-4")
    end
  end
end
