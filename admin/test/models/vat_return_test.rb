require "test_helper"

class VatReturnTest < ActiveSupport::TestCase
  Q3 = VatReturn::Quarter.new(year: 2026, quarter: 3)

  setup do
    travel_to Date.new(2026, 10, 24)
    Invoice.create!(client: clients(:dici), label: "Site", issued_on: "2026-08-10", amount: 1000, vat_amount: 210, status: "issued", source: "okioki", number: "2026-030")
    Invoice.create!(client: clients(:lux), label: "Maintenance", issued_on: "2026-09-01", amount: 500, vat_regime: "intra_eu", status: "issued", source: "okioki", number: "2026-031")
    Invoice.create!(client: clients(:lux), label: "Avoir", kind: "credit_note", issued_on: "2026-09-15", amount: -100, vat_regime: "intra_eu", status: "issued", source: "okioki", number: "2026-032")
  end

  test "quarters" do
    assert_equal [ Date.new(2026, 7, 1), Date.new(2026, 9, 30), Date.new(2026, 10, 20) ], [ Q3.starts_on, Q3.ends_on, Q3.deadline ]
    assert_equal VatReturn::Quarter.new(year: 2027, quarter: 1), VatReturn::Quarter.new(year: 2026, quarter: 4).next
    assert_equal Q3, VatReturn::Quarter.parse("2026-3")
    assert_nil VatReturn::Quarter.parse("2026-5")
  end

  test "grids from sales and purchases" do
    grids = VatReturn.new(Q3).grids
    expected = { "03" => 1000, "44" => 500, "48" => 100, "54" => 210, "55" => 31.5, "59" => 31.5, "71" => 210, "82" => 150, "88" => 150 }
    assert_equal expected, grids.transform_values(&:to_f).transform_values { |value| value == value.round ? value.to_i : value }
  end

  test "intra-EU listing nets credit notes" do
    assert_equal [ { "vat_number" => "LU99999999", "client" => "Client luxembourgeois fictif", "code" => "S", "amount" => "400.0" } ], VatReturn.new(Q3).intracom_listing
  end

  test "a purchase to review blocks the closing, then the quarter freezes its documents" do
    vat_return = VatReturn.new(Q3)
    assert_not vat_return.closable?
    assert_equal [ purchase_invoices(:ai_september) ], vat_return.blocking_controls.sole.documents

    purchase_invoices(:ai_september).book!
    vat_return = VatReturn.new(Q3)
    assert vat_return.closable?
    period = vat_return.close!(user: users(:accountant))
    assert_equal "210.0", period.grids["71"]
    assert_equal period, purchase_invoices(:ai_september).reload.vat_period

    assert_not purchase_invoices(:ai_september).update(amount: 10)
    purchase = purchase_invoices(:ai_september).reload
    assert purchase.update(paid_on: "2026-10-02", notes: "payée")
    assert_not Invoice.find_by!(number: "2026-030").destroy

    late = PurchaseInvoice.create!(supplier: suppliers(:belgian), issued_on: "2026-09-20", amount: 10, vat_amount: 2.1)
    assert_not_includes VatReturn.new(Q3).purchase_invoices, late
    assert_includes VatReturn.new(Q3.next).purchase_invoices, late
  end

  test "quarters close in order" do
    purchase_invoices(:ai_september).book!
    q4 = VatReturn.new(Q3.next)
    travel_to Date.new(2027, 1, 5)
    assert_not q4.previous_closed?
    assert_not q4.closable?
  end

  test "Intervat XML" do
    xml = IntervatXml.new(VatReturn.new(Q3))
    declaration = Nokogiri::XML(xml.declaration)
    declaration.remove_namespaces!
    assert_equal "1000.00", declaration.at("Amount[GridNumber='3']").text
    assert_equal "0999999999", declaration.at("VATNumber").text
    assert_equal [ "3", "2026", "NO" ], %w[ Quarter Year ClientListingNihil ].map { |name| declaration.at(name).text }

    listing = Nokogiri::XML(xml.intracom_listing)
    listing.remove_namespaces!
    assert_equal [ "LU", "99999999", "400.00" ], [ listing.at("CompanyVATNumber")["issuedBy"], listing.at("CompanyVATNumber").text, listing.at("IntraClient Amount").text ]
  end

  test "the accountant pack" do
    purchase = purchase_invoices(:ai_september).reload
    purchase.document.attach(io: file_fixture("invoice.pdf").open, filename: "invoice.pdf")
    CodaImport.new(CodaFixture.file, filename: "belfius.cod").run
    BankStatement.last.update!(statement_on: "2026-09-30")

    zip = Zip::File.open_buffer(AccountantExport.new(VatReturn.new(Q3)).render)
    names = zip.entries.map(&:name)
    assert_includes names, "intervat-2026-T3.xml"
    assert_includes names, "listing-intracom-2026-T3.xml"
    assert_includes names, "achats/#{purchase.id}-#{purchase.to_s.parameterize}.pdf"
    assert_includes names, "banque/2026-09-30-42.cod"
    assert_match "88;150,00", zip.read("grilles.csv")
  end
end
