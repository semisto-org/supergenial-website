require "test_helper"

class OkiokiImportTest < ActiveSupport::TestCase
  CSV_TEXT = <<~CSV
    Numéro;Date;Client;Type;Objet;Montant HTVA;TVA;Total TVAC;Échéance;Statut
    2026-041;15/10/2026;Silvéa;Facture;Maintenance;1.000,00;210,00;1.210,00;14/11/2026;Payée
    2026-042;20/10/2026;Nouveau client fictif;Facture;Site;500,00;105,00;605,00;19/11/2026;Ouverte
    2026-043;22/10/2026;silvea;Note de crédit;Correction;-100,00;-21,00;-121,00;;
  CSV

  setup { Invoice.create!(client: clients(:silvea), source: "okioki", status: "issued", label: "Reprise Sheet", issued_on: Date.new(2026, 1, 1), amount: 999) }

  test "imports invoices and credit notes, replaces numberless references, moves the numbering floor" do
    report = OkiokiImport.new(CSV_TEXT).run
    assert_match "Factures OkiOki : 2 ajout(s)", report

    invoice = Invoice.find_by!(number: "2026-041")
    assert_equal [ clients(:silvea), 1000, 210, Date.new(2026, 10, 15) ], [ invoice.client, invoice.amount, invoice.vat_amount, invoice.paid_on ]
    credit_note = Invoice.find_by!(number: "2026-043")
    assert credit_note.credit_note?
    assert_equal(-100, credit_note.amount)
    assert_equal clients(:silvea), credit_note.client, "matched despite case and accents"
    assert Client.find_by!(name: "Nouveau client fictif").ancien?
    assert_not Invoice.exists?(label: "Reprise Sheet")
    assert_equal "2026-043", CompanyProfile.current.last_external_number

    assert_no_difference -> { Invoice.count } do
      OkiokiImport.new(CSV_TEXT).run
    end
  end

  test "dry run changes nothing" do
    assert_no_difference -> { Invoice.count } do
      assert_match "Simulation", OkiokiImport.new(CSV_TEXT, dry_run: true).run
    end
  end

  test "unknown columns are reported" do
    assert_raises(ArgumentError) { OkiokiImport.new("a,b\n1,2\n").run }
  end
end
