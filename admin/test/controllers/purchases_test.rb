require "test_helper"

class PurchasesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "purchase pages render" do
    [ purchase_invoices_path, purchase_invoices_path(status: "to_review"), purchase_invoice_path(purchase_invoices(:ai_september)),
      new_purchase_invoice_path, edit_purchase_invoice_path(purchase_invoices(:belgian_email)), dependence_path ].each do |path|
      get path
      assert_response :success, path
    end
    get purchase_invoices_path
    assert_select "h2", text: "Exiger Peppol"
  end

  test "upload a purchase by hand, then book it" do
    post purchase_invoices_path, params: { purchase_invoice: { document: fixture_file_upload("invoice.pdf", "application/pdf"), supplier_id: suppliers(:hoster).id,
                                                               number: "H-11", issued_on: "2026-11-01", amount: "50", vat_regime: "outside_eu_services" } }
    purchase = PurchaseInvoice.order(:id).last
    assert_redirected_to purchase_invoice_path(purchase)
    assert_equal [ "manual", expense_categories(:hosting) ], [ purchase.source, purchase.expense_category ]

    get document_purchase_invoice_path(purchase)
    assert_equal "application/pdf", response.media_type

    post book_purchase_invoice_path(purchase)
    assert purchase.reload.booked?
  end

  test "booking an incomplete purchase sends back to the form" do
    purchase = PurchaseInvoice.create!(seller_name: "Inconnu")
    post book_purchase_invoice_path(purchase)
    assert_redirected_to edit_purchase_invoice_path(purchase)
    assert purchase.reload.to_review?
  end

  test "collecting runs the inbox job" do
    assert_enqueued_with(job: PurchaseInboxJob) { post collect_purchase_invoices_path }
  end

  test "the accountant reads and comments purchases but cannot book them" do
    sign_in_as users(:accountant)
    purchase = purchase_invoices(:ai_september)
    get purchase_invoice_path(purchase)
    assert_response :success
    post book_purchase_invoice_path(purchase)
    assert purchase.reload.to_review?
    assert_difference -> { purchase.comments.count } do
      post comments_path, params: { commentable_type: "PurchaseInvoice", commentable_id: purchase.id, comment: { body: "Compte 612 ?" } }
    end
  end
end
