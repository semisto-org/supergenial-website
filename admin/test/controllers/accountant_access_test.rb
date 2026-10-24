require "test_helper"

class AccountantAccessTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:accountant) }

  test "the accountant reads every page" do
    [ root_path, clients_path, client_path(clients(:dici)), invoices_path, fixed_costs_path, suppliers_path,
      supplier_path(suppliers(:hoster)), expense_categories_path, audit_events_path ].each do |path|
      get path
      assert_response :success, path
    end
  end

  test "the accountant cannot open forms or write" do
    get new_client_path
    assert_redirected_to root_path

    assert_no_difference -> { Client.count } do
      post clients_path, params: { client: { name: "Nouveau", kind: "organisation", status: "actif" } }
    end
    patch client_path(clients(:dici)), params: { client: { name: "Renommé" } }
    assert_not_equal "Renommé", clients(:dici).reload.name
    delete supplier_path(suppliers(:hoster))
    assert Supplier.exists?(suppliers(:hoster).id)
  end

  test "the accountant cannot manage accounts" do
    get users_path
    assert_redirected_to root_path
  end

  test "the accountant comments and validates a category" do
    assert_difference -> { clients(:dici).comments.count } do
      post comments_path(commentable_type: "Client", commentable_id: clients(:dici).id), params: { comment: { body: "Facture manquante ?" } }
    end
    assert_equal users(:accountant), Comment.last.user

    patch validate_expense_category_path(expense_categories(:hosting))
    assert expense_categories(:hosting).reload.validated?
  end

  test "comments only target known record types" do
    post comments_path(commentable_type: "User", commentable_id: users(:one).id), params: { comment: { body: "x" } }
    assert_response :unprocessable_entity
  end
end
