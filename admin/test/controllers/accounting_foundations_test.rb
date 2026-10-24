require "test_helper"

class AccountingFoundationsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "pages render" do
    [ suppliers_path, suppliers_path(zone: "us"), supplier_path(suppliers(:ai_company)), new_supplier_path, edit_supplier_path(suppliers(:hoster)),
      expense_categories_path, new_expense_category_path, edit_expense_category_path(expense_categories(:hosting)),
      audit_events_path, users_path, new_user_path, edit_user_path(users(:accountant)) ].each do |path|
      get path
      assert_response :success, path
    end
  end

  test "every change is journaled with its author" do
    assert_difference -> { AuditEvent.count }, 2 do
      post suppliers_path, params: { supplier: { name: "Nouveau fournisseur", billing_country: "FR" } }
      patch supplier_path(Supplier.find_by!(name: "Nouveau fournisseur")), params: { supplier: { billing_country: "BE" } }
    end
    event = AuditEvent.recent.first
    assert_equal [ "update", "Supplier", users(:one) ], [ event.action, event.auditable_type, event.user ]
    assert_equal [ "FR", "BE" ], event.changeset["billing_country"]

    get audit_events_path(type: "Supplier")
    assert_response :success
  end

  test "the journal never stores secrets" do
    Current.user = users(:one)
    users(:two).update!(password: "another-password")
    assert_equal "[filtré]", AuditEvent.recent.first.changeset["password_digest"].last
  end

  test "create an accountant account" do
    post users_path, params: { user: { name: "Comptable", email_address: "Nouvelle@Example.com", role: "accountant", password: "a-long-password" } }
    assert_redirected_to users_path
    user = User.find_by!(email_address: "nouvelle@example.com")
    assert user.accountant?
    assert_not user.can_write?
  end

  test "reset someone's two-factor" do
    post reset_two_factor_user_path(users(:accountant))
    assert_not users(:accountant).reload.two_factor_enabled?
  end
end
