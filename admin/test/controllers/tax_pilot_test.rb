require "test_helper"

class TaxPilotTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "tax pages render and the plan is saved" do
    [ tax_projection_path, tax_projection_path(year: 2027), tax_parameters_path, new_tax_parameter_path(from: tax_parameters(:isoc_reduced_rate).id),
      edit_tax_parameter_path(tax_parameters(:plci_ceiling)) ].each do |path|
      get path
      assert_response :success, path
    end
    patch tax_projection_path(year: 2026), params: { fiscal_plan: { monthly_remuneration: "4000", year_end_remuneration: "0", plci_amount: "3000" } }
    assert_redirected_to tax_projection_path(year: 2026)
    assert_equal 4000, FiscalPlan.find_by!(year: 2026).monthly_remuneration
  end

  test "a new value starts on its own date" do
    post tax_parameters_path, params: { tax_parameter: { key: "isoc_reduced_rate", label: "Taux réduit", value: "19", valid_from: "2027-01-01" } }
    assert_equal 20, TaxParameter.value(:isoc_reduced_rate, on: Date.new(2026, 12, 31))
    assert_equal 19, TaxParameter.value(:isoc_reduced_rate, on: Date.new(2027, 12, 31))
  end

  test "the accountant confirms parameters but cannot change them" do
    sign_in_as users(:accountant)
    parameter = tax_parameters(:plci_ceiling)
    patch verify_tax_parameter_path(parameter)
    assert parameter.reload.verified?
    patch tax_parameter_path(parameter), params: { tax_parameter: { value: "1" } }
    assert_equal 3915, parameter.reload.value
    get tax_projection_path
    assert_response :success
  end
end
