require "csv"

# Imports the invoices and credit notes exported from OkiOki (CSV), as issued OkiOki references.
# Columns are recognised by their header (French or English), whatever their order.
# Idempotent: a document already imported (same number) is updated, not duplicated.
class OkiokiImport < HistoryImport
  HEADERS = {
    number: [ "numero", "n", "numero de facture", "numero du document", "number", "invoice number", "document" ],
    date: [ "date", "date de facture", "date du document", "date d emission", "date de facturation", "issue date", "invoice date" ],
    client: [ "client", "nom du client", "customer", "destinataire", "societe" ],
    kind: [ "type", "type de document", "document type" ],
    label: [ "objet", "libelle", "description", "titre", "reference", "subject" ],
    net: [ "montant htva", "total htva", "htva", "hors tva", "montant ht", "total ht", "total excl tva", "subtotal", "net" ],
    vat: [ "tva", "montant tva", "total tva", "vat", "tax" ],
    total: [ "total", "total tvac", "montant tvac", "tvac", "ttc", "total ttc", "total incl tva", "montant" ],
    due: [ "echeance", "date d echeance", "due date" ],
    paid: [ "paye le", "date de paiement", "paid on", "payment date" ],
    status: [ "statut", "etat", "status" ]
  }.freeze

  def initialize(csv, replace_unnumbered: true, **options)
    super(**options)
    @csv, @replace_unnumbered = csv, replace_unnumbered
  end

  private
    def import
      rows = parse
      raise ArgumentError, "Colonnes introuvables : numéro, date, client et montant sont nécessaires. En-têtes lus : #{@headers.join(', ')}" unless rows

      replace_unnumbered_references(rows.filter_map { |row| row[:date]&.year }.uniq) if @replace_unnumbered
      rows.each { |row| import_row(row) }
      update_numbering_floor
    end

    def parse
      text = @csv.dup.force_encoding("UTF-8").delete_prefix("﻿")
      text = @csv.dup.force_encoding("Windows-1252").encode("UTF-8") unless text.valid_encoding?
      separator = text.lines.first.to_s.count(";") > text.lines.first.to_s.count(",") ? ";" : ","
      table = CSV.parse(text, col_sep: separator, headers: true)
      @headers = table.headers.compact
      columns = HEADERS.transform_values { |names| @headers.find { |header| names.include?(normalize_header(header)) } }
      return nil unless columns.values_at(:number, :date, :client).all? && (columns[:net] || columns[:total])

      table.filter_map do |row|
        next if row[columns[:number]].blank?
        columns.transform_values { |header| header && row[header] }.then do |values|
          values.merge(date: parse_date(values[:date]), net: parse_amount(values[:net]), vat: parse_amount(values[:vat]),
                       total: parse_amount(values[:total]), due: parse_date(values[:due]), paid: parse_date(values[:paid]))
        end
      end
    end

    def normalize_header(header) = I18n.transliterate(header.to_s).downcase.gsub(/[^a-z0-9]+/, " ").strip

    def import_row(row)
      number = row[:number].strip
      unless row[:date]
        warn "#{number} : date illisible, ignoré"
        return skip("Documents OkiOki")
      end

      credit_note = row[:kind].to_s.match?(/cr[ée]dit|avoir|credit/i) || [ row[:net], row[:total] ].compact.first.to_d.negative?
      net = row[:net] || (row[:total] && row[:vat] ? row[:total] - row[:vat] : row[:total])
      warn "#{number} : pas de montant HTVA, total TVAC repris" if row[:net].nil? && row[:vat].nil?
      sign = credit_note ? -1 : 1

      invoice = Invoice.find_or_initialize_by(source: "okioki", number:)
      invoice.assign_attributes(
        client: find_or_create_client(row[:client]), status: "issued", kind: credit_note ? "credit_note" : "invoice",
        issued_on: row[:date], due_on: row[:due], label: row[:label].presence || invoice.label.presence || "Facture OkiOki #{number}",
        amount: sign * net.abs, vat_amount: row[:vat]&.abs || 0, paid_on: paid_on(row, number)
      )
      invoice.save!
      count(invoice, credit_note ? "Notes de crédit OkiOki" : "Factures OkiOki")
    end

    def paid_on(row, number)
      return row[:paid] if row[:paid]
      return nil unless row[:status].to_s.match?(/pay[ée]|paid|sold[ée]/i)
      warn "#{number} : payée sans date de paiement, date de facture reprise"
      row[:date]
    end

    # The Google Sheet import created OkiOki references without a number: the real documents replace them.
    # Their hours stay billed.
    def replace_unnumbered_references(years)
      years.each do |year|
        scope = Invoice.okioki.where(number: nil).in_year(year)
        next if scope.none?
        TimeEntry.where(invoice_id: scope.select(:id)).update_all(invoice_id: nil)
        Pack.where(invoice_id: scope.select(:id)).update_all(invoice_id: nil)
        removed = scope.destroy_all.size
        warn "#{removed} référence(s) sans numéro de #{year} (reprises de la Google Sheet) remplacée(s) par les documents OkiOki"
      end
    end

    # Numbering of the admin continues after the last OkiOki document of the year.
    def update_numbering_floor
      year = Date.current.year
      last = Invoice.okioki.where("number LIKE ?", "#{year}-%").pluck(:number).max_by { |number| number[/\d+\z/].to_i }
      company = CompanyProfile.current
      return if last.nil? || company.last_external_number.to_s[/\d+\z/].to_i >= last[/\d+\z/].to_i
      company.update!(last_external_number: last)
      warn "Dernier numéro OkiOki mis à jour : #{last}"
    end
end
