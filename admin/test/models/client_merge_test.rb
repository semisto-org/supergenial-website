require "test_helper"

class ClientMergeTest < ActiveSupport::TestCase
  test "moves everything the duplicate owns, fills blank details, then deletes it" do
    kept = clients(:silvea)
    duplicate = clients(:dici)
    duplicate.contacts.create!(first_name: "Alice", primary: false)
    kept.contacts.create!(first_name: "Zoé", primary: true)
    duplicate.comments.create!(body: "Ancien doublon", user: users(:one))
    issued = duplicate.invoices.create!(label: "Atelier", issued_on: "2026-05-01", source: "admin", status: "draft",
                                        lines_attributes: [ { description: "Atelier", quantity: 1, unit_price: 100 } ])
    issued.update_columns(status: "issued", number: "2026-099")
    owned = %i[ contacts projects time_entries contracts packs invoices comments ].index_with { |association| duplicate.public_send(association).count }

    merge = ClientMerge.new(kept:, duplicate:).merge!

    assert_not Client.exists?(duplicate.id)
    owned.each { |association, count| assert_equal count, merge.moved[association], association }
    assert_equal "BE0888888888", kept.reload.vat_number
    assert_equal "Namur", kept.city
    assert_equal kept, issued.reload.client
    assert_equal [ "Zoé" ], kept.contacts.where(primary: true).map(&:first_name), "the kept client keeps its primary contact"
    assert TimeEntry.where(client: kept).all?(&:valid?)
  end

  test "issued admin invoices still refuse a client change outside a merge" do
    invoice = clients(:dici).invoices.create!(label: "Atelier", issued_on: "2026-05-01", source: "admin", status: "draft",
                                              lines_attributes: [ { description: "Atelier", quantity: 1, unit_price: 100 } ])
    invoice.update_columns(status: "issued", number: "2026-098")
    assert_not invoice.reload.update(client: clients(:silvea))
  end

  test "refuses to merge a client into itself" do
    assert_raises(ClientMerge::Error) { ClientMerge.new(kept: clients(:dici), duplicate: clients(:dici)).merge! }
  end
end
