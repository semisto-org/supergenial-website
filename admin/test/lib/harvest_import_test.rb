require "test_helper"

class HarvestImportTest < ActiveSupport::TestCase
  class FakeApi
    DATA = {
      "clients" => [ { "id" => 11, "name" => "D'ICI", "address" => "" }, { "id" => 12, "name" => "Ancien client fictif", "address" => "Rue 1" } ],
      "invoices" => [
        { "id" => 101, "client" => { "id" => 12, "name" => "Ancien client fictif" }, "number" => "2019-004", "state" => "paid", "amount" => 121.0,
          "tax" => 21.0, "tax_amount" => 21.0, "tax2_amount" => nil, "subject" => "Site", "issue_date" => "2019-03-01", "due_date" => "2019-03-31",
          "paid_date" => "2019-03-15", "currency" => "EUR", "line_items" => [ { "kind" => "Service", "description" => "Dev", "quantity" => 2, "unit_price" => 50, "taxed" => true } ] },
        { "id" => 102, "client" => { "id" => 11, "name" => "D'ICI" }, "number" => "2019-005", "state" => "draft", "amount" => 10 }
      ],
      "time_entries" => [
        { "id" => 1001, "spent_date" => "2019-02-20", "hours" => 2.0, "notes" => "Dev", "client" => { "id" => 12, "name" => "Ancien client fictif" },
          "project" => { "name" => "Site" }, "task" => { "name" => "Développement" }, "billable" => true, "is_billed" => true, "invoice" => { "id" => 101 } },
        { "id" => 1002, "spent_date" => "2019-02-21", "hours" => 1.0, "client" => { "id" => 11, "name" => "D'ICI" }, "billable" => true, "is_billed" => false, "invoice" => nil }
      ]
    }.freeze

    def each(collection, **) = DATA.fetch(collection).each { |record| yield record }
  end

  test "imports clients, issued invoices with lines, and time entries" do
    report = HarvestImport.new(api: FakeApi.new, time_entries_until: Date.new(2019, 12, 31)).run
    assert_match "Factures Harvest : 1 ajout(s), 0 mise(s) à jour, 1 ignoré(s)", report

    assert_equal 11, clients(:dici).reload.harvest_id
    invoice = Invoice.harvest.find_by!(number: "2019-004")
    assert_equal [ 100, 21, 1 ], [ invoice.amount, invoice.vat_amount, invoice.lines.size ]
    assert invoice.issued?

    billed = TimeEntry.find_by!(external_id: "harvest:1001")
    assert_equal invoice, billed.invoice
    assert billed.facture?
    assert TimeEntry.find_by!(external_id: "harvest:1002").offert?

    assert_no_difference [ -> { Invoice.count }, -> { TimeEntry.count }, -> { Client.count } ] do
      HarvestImport.new(api: FakeApi.new, time_entries_until: Date.new(2019, 12, 31)).run
    end
  end
end
