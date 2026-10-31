require "test_helper"

class OkiokiArchiveImportTest < ActiveSupport::TestCase
  setup { @file = OkiokiArchiveFixture.file }
  teardown { @file.close! }

  def run_import(**options) = OkiokiArchiveImport.new(@file.path, **options).run

  test "imports sales, purchases, payments and exchange rates; skips bank statements" do
    report = run_import
    assert_match "Factures OkiOki : 2 ajout(s)", report
    assert_match "Achats OkiOki : 3 ajout(s)", report
    assert_match "Extraits de compte", report
    assert_match "900007_0000000000_16_10_2026.pdf : PDF sans données UBL", report

    sale = Invoice.find_by!(source: "okioki", number: "2026-050")
    assert_equal [ clients(:silvea), 1000, 210, Date.new(2026, 10, 25), "Maintenance fictive", "900001" ],
                 [ sale.client, sale.amount, sale.vat_amount, sale.paid_on, sale.label, sale.external_id ]
    assert sale.document.attached?
    assert_includes sale.ubl_xml, "2026-050"

    intra = Invoice.find_by!(number: "2026-051")
    assert_equal "intra_eu", intra.vat_regime
    assert_equal "FR00999999999", intra.client.vat_number
    assert_not Invoice.exists?(number: "2026-099"), "a bank statement is not a sale"
    assert_equal "2026-051", CompanyProfile.current.last_external_number

    usd = PurchaseInvoice.find_by!(external_id: "900002")
    assert_equal [ "USD", 12, 0.9.to_d, 10.8.to_d, Date.new(2026, 6, 16) ], [ usd.currency, usd.original_amount, usd.exchange_rate, usd.amount, usd.paid_on ]
    assert usd.booked?, "dated before the tracked VAT period"
    assert usd.document.attached?
    assert_equal "US", usd.supplier.billing_country
    assert_equal "outside_eu_services", usd.vat_regime

    unpaid = PurchaseInvoice.find_by!(external_id: "900006")
    assert_equal usd.supplier, unpaid.supplier, "same supplier despite case and legal form"
    assert_equal 0.9.to_d, unpaid.exchange_rate, "monthly rate when no payment is linked"

    belgian = PurchaseInvoice.find_by!(external_id: "900003")
    assert_equal [ suppliers(:belgian), 100, 21, "domestic" ], [ belgian.supplier, belgian.amount, belgian.vat_amount, belgian.vat_regime ]
    assert belgian.to_review?, "a purchase of the tracked VAT period still has to be checked"
  end

  test "runs again without duplicating and keeps corrections" do
    run_import
    PurchaseInvoice.find_by!(external_id: "900003").update!(number: "B-7 corrigé")
    assert_no_difference %w[ Invoice.count PurchaseInvoice.count Supplier.count Client.count ] do
      run_import
    end
    assert_equal "B-7 corrigé", PurchaseInvoice.find_by!(external_id: "900003").number
  end

  test "a dry run changes nothing" do
    assert_no_difference %w[ Invoice.count PurchaseInvoice.count ActiveStorage::Blob.count ] do
      assert_match "Simulation", run_import(dry_run: true)
    end
  end

  test "reads xlsx cells" do
    sheets = XlsxReader.new(OkiokiArchiveFixture.xlsx([ [ Date.new(2026, 6, 16), -10.8, "-12.00 USD", "900002" ] ])).sheets
    header, row = sheets.fetch("BE00")
    assert_equal "ExecutionDate", header[1]
    assert_equal Date.new(2026, 6, 16), XlsxReader.date(row[1])
    assert_equal(-10.8.to_d, row[8])
    assert_equal "900002", row[12]
  end
end
