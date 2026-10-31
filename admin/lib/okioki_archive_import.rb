require "zip"
require "nokogiri"

# Imports the full archive exported from OkiOki (ZIP):
# - the UBL (and PDF) of every sales document, as issued OkiOki references (matched by number);
# - the UBL (and PDF) of every purchase document, as purchase invoices (matched by OkiOki id);
# - the monthly bank transactions (YYYYMM/transactions.xlsx), which give the payment dates and, for
#   documents in a foreign currency, the euro amount actually paid.
# Bank statements filed as documents (<IBAN>_<date>_<sequence>) are skipped: CODA files carry them.
#
# Purchases dated before « TVA suivie depuis » were already booked by the accountant: they come in booked.
# Later ones still have to be checked, since they feed the next VAT return.
# A purchase imported earlier keeps what was corrected in the admin; only its payment date and PDF are filled in.
class OkiokiArchiveImport < OkiokiImport
  STATEMENT_NAME = /_[A-Z]{2}\d{14,32}_\d{8}_\d{5}/
  NUMBER_IN_NAME = /invoice_(\d{4})_(\d{3})/
  SALES_NUMBER = /\A\d{4}-\d{3}\z/
  MAX_ENTRY_SIZE = 30.megabytes
  LEGAL_FORMS = %w[ inc ltd llc limited sas sa srl sprl bv nv gmbh sarl pte corp plc co ].freeze

  Document = Struct.new(:key, :id, :xml_entry, :pdf_entry, keyword_init: true)
  Transaction = Struct.new(:booked_on, :amount, :foreign_amount, :foreign_currency, :document_ids, keyword_init: true)

  def initialize(path, **options)
    super(nil, **options)
    @path = path
  end

  private
    def import
      Zip::File.open(@path) do |zip|
        read_archive(zip)
        documents = @documents.values.select(&:xml_entry).map { |document| [ document, parse(document.xml_entry) ] }
        sales, purchases = documents.partition { |_, xml| sale?(xml) }
        replace_unnumbered_references(sales.filter_map { |_, xml| date(xml, "IssueDate")&.year }.uniq) if @replace_unnumbered
        sales.each { |document, xml| import_sale(document, xml) }
        purchases.each { |document, xml| import_purchase(document, xml) }
      end
      @documents.values.reject(&:xml_entry).each do |document|
        warn "#{document.key}.pdf : PDF sans données UBL, non repris (déclaration, rapport…)"
        skip("PDF sans données")
      end
      update_numbering_floor
    end

    def read_archive(zip)
      @documents, @transactions = {}, Hash.new { |hash, key| hash[key] = [] }
      zip.each do |entry|
        next unless entry.file?
        name = File.basename(entry.name)
        extension = File.extname(name).downcase
        if name.casecmp?("transactions.xlsx")
          read_transactions(entry)
        elsif extension.in?(%w[ .xml .pdf ])
          next skip("Extraits de compte") if name.match?(STATEMENT_NAME) && extension == ".pdf"
          next if name.match?(STATEMENT_NAME)
          raise ArgumentError, "#{name} est trop lourd (#{MAX_ENTRY_SIZE / 1.megabyte} Mo maximum)" if entry.size > MAX_ENTRY_SIZE
          key = name.delete_suffix(File.extname(name))
          document = @documents[key] ||= Document.new(key:, id: key[/(?:\A|_)(\d{6})(?=_|\z)/, 1])
          extension == ".xml" ? document.xml_entry = entry : document.pdf_entry = entry
        end
      end
      raise ArgumentError, "Aucun document OkiOki dans ce ZIP (fichiers .xml et .pdf attendus)." if @documents.empty?
    end

    def read_transactions(entry)
      XlsxReader.new(entry.get_input_stream.read).sheets.each_value do |rows|
        header = rows.first.to_a.map(&:to_s)
        cell = ->(row, name) { header.index(name)&.then { |index| row[index] } }
        rows.drop(1).each do |row|
          ids = cell.(row, "DocumentOkiOkiIds").to_s.split(",").map(&:strip).compact_blank
          next if ids.empty?
          foreign = cell.(row, "ForeignAmount").to_s.match(/(-?[\d.,]+)\s*([A-Z]{3})/)
          transaction = Transaction.new(booked_on: XlsxReader.date(cell.(row, "ExecutionDate")), amount: cell.(row, "Amount").to_s.to_d,
                                        foreign_amount: foreign && foreign[1].delete(",").to_d, foreign_currency: foreign&.[](2), document_ids: ids)
          ids.each { |id| @transactions[id] << transaction }
        end
      end
    end

    def parse(entry)
      raw = entry.get_input_stream.read.force_encoding(Encoding::UTF_8)
      Nokogiri::XML(raw).remove_namespaces!.tap { |xml| xml.instance_variable_set(:@raw, raw) }
    end

    def raw(xml) = xml.instance_variable_get(:@raw)

    # --- Sales ---

    def sale?(xml)
      seller = party(xml, "AccountingSupplierParty")
      company = CompanyProfile.current
      (company.vat_number.present? && seller[:vat_number] == vat_number(company.vat_number, "BE")) ||
        seller[:name].present? && normalize(seller[:name]) == normalize(company.legal_name)
    end

    def import_sale(document, xml)
      number = document.key[NUMBER_IN_NAME] ? "#{$1}-#{$2}" : text(xml, "/*/ID")
      unless number.match?(SALES_NUMBER)
        warn "#{document.key} : numéro de vente illisible (#{number}), non repris"
        return skip("Factures OkiOki")
      end
      buyer = party(xml, "AccountingCustomerParty")
      client = sale_client(buyer)
      unless client
        warn "#{number} : client sans nom, non repris"
        return skip("Factures OkiOki")
      end

      net, vat = amount(xml, "LegalMonetaryTotal/TaxExclusiveAmount"), amount(xml, "TaxTotal/TaxAmount")
      credit_note = credit_note?(xml, net)
      invoice = Invoice.find_or_initialize_by(source: "okioki", number:)
      invoice.assign_attributes(
        client:, status: "issued", kind: credit_note ? "credit_note" : "invoice", external_id: document.id,
        issued_on: date(xml, "IssueDate"), due_on: date(xml, "DueDate"), label: invoice.label.presence || sale_label(xml, number),
        amount: (credit_note ? -1 : 1) * net.abs, vat_amount: vat.abs, vat_regime: sales_regime(buyer, vat),
        buyer: buyer.compact_blank.stringify_keys, ubl_xml: raw(xml), paid_on: invoice.paid_on || payment_date(document.id)
      )
      attach_pdf(invoice, document, xml)
      save(invoice, credit_note ? "Notes de crédit OkiOki" : "Factures OkiOki", number)
    end

    def sale_client(buyer)
      return if buyer[:name].blank?
      client = (Client.find_by(vat_number: buyer[:vat_number]) if buyer[:vat_number].present?)
      client ||= find_or_create_client(buyer[:name], vat_number: buyer[:vat_number], country: known_country(buyer[:country]) || "BE",
                                       street: buyer[:street], postal_code: buyer[:postal_code], city: buyer[:city], billing_email: buyer[:email])
      client.update!(vat_number: buyer[:vat_number]) if client.vat_number.blank? && buyer[:vat_number].present?
      client
    end

    def sale_label(xml, number)
      name = xml.xpath("/*/InvoiceLine/Item/Name | /*/CreditNoteLine/Item/Name").map { |node| node.text.strip }.find { |text| text.present? && !text.match?(/, invoice /) }
      name ? name.truncate(200) : "Facture OkiOki #{number}"
    end

    def sales_regime(buyer, vat)
      return "standard" if vat.nonzero? || buyer[:country].blank? || buyer[:country] == "BE"
      return "outside_eu" unless Country::EU.include?(buyer[:country])
      buyer[:vat_number].present? ? "intra_eu" : "standard"
    end

    # --- Purchases ---

    def import_purchase(document, xml)
      purchase = PurchaseInvoice.find_or_initialize_by(source: "okioki", external_id: document.id || document.key)
      if purchase.persisted?
        purchase.paid_on ||= payment_date(document.id)
        attach_pdf(purchase, document, xml) unless purchase.document.attached?
        return save(purchase, "Achats OkiOki", document.key)
      end

      seller = party(xml, "AccountingSupplierParty")
      currency = text(xml, "DocumentCurrencyCode").presence&.upcase || "EUR"
      net, vat, total = amount(xml, "LegalMonetaryTotal/TaxExclusiveAmount"), amount(xml, "TaxTotal/TaxAmount"), amount(xml, "LegalMonetaryTotal/PayableAmount")
      issued_on = date(xml, "IssueDate")
      rate = currency == "EUR" ? 1 : exchange_rate(document, currency, total.nonzero? || net + vat, issued_on)

      purchase.assign_attributes(
        kind: credit_note?(xml, net.nonzero? || total) ? "credit_note" : "invoice", number: text(xml, "/*/ID").presence,
        issued_on:, due_on: date(xml, "DueDate"), currency:, exchange_rate: rate || 1, original_amount: net.abs,
        vat_amount: (vat.abs * (rate || 1)).round(2), vat_rate: vat_rate(xml), seller_name: seller[:name].presence,
        seller_vat_number: seller[:vat_number], seller_country: seller[:country], paid_on: payment_date(document.id)
      )
      purchase.amount = net.abs if currency == "EUR"
      purchase.supplier = purchase_supplier(seller, currency, document.key)
      purchase.match_supplier
      purchase.vat_regime = PurchaseVatRegime.suggest(country: purchase.country, vat_amount: purchase.vat_amount)
      if issued_on && issued_on < tracked_since && rate
        purchase.status, purchase.booked_at = "booked", Time.current
      end
      attach_pdf(purchase, document, xml)
      save(purchase, "Achats OkiOki", document.key)
    end

    def purchase_supplier(seller, currency, key)
      return if seller[:name].blank?
      @suppliers ||= Supplier.all.to_a
      supplier = (@suppliers.find { |known| known.vat_number == seller[:vat_number] } if seller[:vat_number].present?)
      supplier ||= @suppliers.find { |known| supplier_key(known.name) == supplier_key(seller[:name]) }
      supplier || begin
        country = known_country(seller[:country]) || (currency == "USD" ? "US" : nil)
        warn "#{key} : pays de #{seller[:name]} inconnu, Belgique mise par défaut (à corriger dans la fiche)" unless country
        Supplier.create!(name: seller[:name].strip.truncate(100), vat_number: seller[:vat_number], billing_country: country || "BE").tap do |created|
          @suppliers << created
          count(created, "Fournisseurs")
        end
      end
    end

    def supplier_key(name)
      (normalize_words(name) - LEGAL_FORMS).join
    end

    def normalize_words(name) = I18n.transliterate(name.to_s).downcase.gsub(/[^a-z0-9]+/, " ").split

    # The euro amount debited for the document, compared with the amount in its currency.
    def exchange_rate(document, currency, total, issued_on)
      linked = @transactions[document.id]
      rates = linked.filter_map { |transaction| (transaction.amount / transaction.foreign_amount).abs if transaction.foreign_currency == currency && transaction.foreign_amount.to_d.nonzero? }
      if rates.empty? && linked.any? && linked.all? { |transaction| transaction.document_ids == [ document.id ] && transaction.foreign_currency.nil? } && total.to_d.nonzero?
        rates << (linked.sum(&:amount) / total).abs
      end
      return (rates.sum / rates.size).round(6) if rates.any?

      rate = month_rate(currency, issued_on)
      if rate
        warn "#{document.key} : pas de paiement lié, taux #{currency} moyen du mois repris (#{rate.round(4)})"
      else
        warn "#{document.key} : aucun taux #{currency} trouvé, montant à convertir à la main"
      end
      rate
    end

    def month_rate(currency, on)
      @month_rates ||= @transactions.values.flatten.uniq.select { |transaction| transaction.foreign_currency && transaction.foreign_amount.to_d.nonzero? && transaction.booked_on }
                                    .group_by { |transaction| [ transaction.foreign_currency, transaction.booked_on.beginning_of_month ] }
                                    .transform_values { |transactions| (transactions.sum { |transaction| (transaction.amount / transaction.foreign_amount).abs } / transactions.size).round(6) }
      return nil unless on
      months = @month_rates.keys.select { |known, _| known == currency }.map(&:last)
      closest = months.min_by { |month| (month - on.beginning_of_month).abs }
      closest && @month_rates[[ currency, closest ]]
    end

    def vat_rate(xml)
      percents = xml.xpath("/*/TaxTotal/TaxSubtotal/TaxCategory/Percent").map { |node| node.text.to_d }
      percents.max.to_d.positive? ? percents.max : 21
    end

    def tracked_since = @tracked_since ||= CompanyProfile.current.vat_tracked_since || Date.current

    # --- Shared ---

    def save(record, label, reference)
      record.save!
      count(record, label)
    rescue ActiveRecord::RecordInvalid => error
      warn "#{reference} : non repris (#{error.record.errors.full_messages.to_sentence})"
      skip(label)
    end

    def attach_pdf(record, document, xml)
      data = document.pdf_entry&.get_input_stream&.read
      data ||= xml.at_xpath("/*/AdditionalDocumentReference/Attachment/EmbeddedDocumentBinaryObject[@mimeCode='application/pdf']")&.text&.then { |base64| Base64.decode64(base64) }
      return if data.blank?
      record.document.attach(io: StringIO.new(data), filename: "#{document.key}.pdf", content_type: "application/pdf")
    end

    def payment_date(id) = id && @transactions[id].filter_map(&:booked_on).min

    def credit_note?(xml, amount) = xml.root.name == "CreditNote" || text(xml, "InvoiceTypeCode") == "381" || amount.to_d.negative?

    def party(xml, role)
      node = xml.at_xpath("/*/#{role}/Party")
      return {} unless node
      country = node.at_xpath("PostalAddress/Country/IdentificationCode")&.text&.strip&.upcase.presence
      {
        name: (node.at_xpath("PartyLegalEntity/RegistrationName") || node.at_xpath("PartyName/Name"))&.text&.strip,
        vat_number: vat_number(node.at_xpath("PartyTaxScheme/CompanyID")&.text, country),
        country: country || vat_country(node.at_xpath("PartyTaxScheme/CompanyID")&.text),
        street: node.at_xpath("PostalAddress/StreetName")&.text&.strip, postal_code: node.at_xpath("PostalAddress/PostalZone")&.text&.strip,
        city: node.at_xpath("PostalAddress/CityName")&.text&.strip, email: node.at_xpath("Contact/ElectronicMail")&.text&.strip
      }
    end

    # "0523.920.556" → "BE0523920556"; foreign numbers keep their prefix.
    def vat_number(value, country)
      number = value.to_s.upcase.gsub(/[^A-Z0-9]/, "")
      return nil if number.empty?
      number.match?(/\A\d{10}\z/) && country.in?([ nil, "BE" ]) ? "BE#{number}" : number
    end

    def vat_country(value) = known_country(value.to_s.upcase[/\A[A-Z]{2}/])

    def known_country(code) = code.presence && Country::NAMES.key?(code) ? code : nil

    def text(xml, path) = xml.at_xpath(path.start_with?("/") ? path : "/*/#{path}")&.text.to_s.strip

    def amount(xml, path) = text(xml, path).presence&.to_d || 0.to_d

    def date(xml, path) = text(xml, path).presence&.then { |value| Date.iso8601(value) rescue nil }
end
