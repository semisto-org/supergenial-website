require "zip"

# Builds a fictive OkiOki archive: UBL documents with their PDF, a bank statement filed as a document,
# a PDF without UBL and a monthly transactions.xlsx. Only fictive data.
module OkiokiArchiveFixture
  PDF = File.binread(File.expand_path("../fixtures/files/invoice.pdf", __dir__))

  module_function

  def ubl(number:, date:, seller:, buyer:, net:, vat:, currency: "EUR", item: "Prestation fictive", percent: 21, credit_note: false)
    root = credit_note ? "CreditNote" : "Invoice"
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <#{root} xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns="urn:oasis:names:specification:ubl:schema:xsd:#{root}-2">
        <cbc:ProfileID>FFF.BE OkiOki</cbc:ProfileID>
        <cbc:ID>#{number}</cbc:ID>
        <cbc:IssueDate>#{date}</cbc:IssueDate>
        <cbc:DueDate>#{date}</cbc:DueDate>
        <cbc:InvoiceTypeCode>#{credit_note ? 381 : 380}</cbc:InvoiceTypeCode>
        <cbc:DocumentCurrencyCode>#{currency}</cbc:DocumentCurrencyCode>
        #{party("AccountingSupplierParty", **seller)}
        #{party("AccountingCustomerParty", **buyer)}
        <cac:TaxTotal>
          <cbc:TaxAmount currencyID="#{currency}">#{vat}</cbc:TaxAmount>
          <cac:TaxSubtotal><cac:TaxCategory><cbc:ID>S</cbc:ID><cbc:Percent>#{percent}</cbc:Percent></cac:TaxCategory></cac:TaxSubtotal>
        </cac:TaxTotal>
        <cac:LegalMonetaryTotal>
          <cbc:TaxExclusiveAmount currencyID="#{currency}">#{net}</cbc:TaxExclusiveAmount>
          <cbc:PayableAmount currencyID="#{currency}">#{(net.to_d + vat.to_d).to_s("F")}</cbc:PayableAmount>
        </cac:LegalMonetaryTotal>
        <cac:#{root}Line><cac:Item><cbc:Name>#{item}</cbc:Name></cac:Item></cac:#{root}Line>
      </#{root}>
    XML
  end

  def party(role, name:, vat: nil, country: "BE")
    <<~XML
      <cac:#{role}><cac:Party>
        <cac:PartyName><cbc:Name>#{name}</cbc:Name></cac:PartyName>
        <cac:PostalAddress><cbc:StreetName>Rue fictive 2</cbc:StreetName><cbc:CityName>Namur</cbc:CityName><cbc:PostalZone>5000</cbc:PostalZone><cac:Country><cbc:IdentificationCode>#{country}</cbc:IdentificationCode></cac:Country></cac:PostalAddress>
        #{"<cac:PartyTaxScheme><cbc:CompanyID>#{vat}</cbc:CompanyID></cac:PartyTaxScheme>" if vat}
        <cac:PartyLegalEntity><cbc:RegistrationName>#{name}</cbc:RegistrationName></cac:PartyLegalEntity>
      </cac:Party></cac:#{role}>
    XML
  end

  # rows: [ [ date, amount, foreign ("-11.00 USD" or nil), document ids ("900002") ], … ]
  def xlsx(rows)
    header = %w[ AccountNumber ExecutionDate ValutaDate CounterPartyName CounterPartyAccountNumber Description Remittance TransactionType Amount Currency ForeignAmount TransactionOkiOkiId DocumentOkiOkiIds Tags Comments ]
    strings = []
    string = ->(text) { strings.index(text) || (strings << text).size - 1 }
    cell = ->(column, row, value) do
      reference = "#{(65 + column).chr}#{row}"
      value.is_a?(Numeric) ? %(<c r="#{reference}"><v>#{value}</v></c>) : %(<c r="#{reference}" t="s"><v>#{string.(value.to_s)}</v></c>)
    end
    lines = [ header.each_with_index.map { |title, column| cell.(column, 1, title) } ]
    rows.each_with_index do |(date, amount, foreign, ids), index|
      serial = (date - XlsxReader::EPOCH).to_i
      values = { 0 => "BE00 0000 0000 0000", 1 => serial, 2 => serial, 8 => amount, 9 => "EUR", 10 => foreign, 12 => ids }.compact
      lines << values.map { |column, value| cell.(column, index + 2, value) }
    end
    sheet = %(<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>#{lines.each_with_index.map { |cells, index| %(<row r="#{index + 1}">#{cells.join}</row>) }.join}</sheetData></worksheet>)
    shared = %(<?xml version="1.0" encoding="UTF-8"?><sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">#{strings.map { |text| "<si><t>#{text.encode(xml: :text)}</t></si>" }.join}</sst>)
    workbook = %(<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="BE00" sheetId="1" r:id="rId1"/></sheets></workbook>)
    relations = %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="worksheet" Target="worksheets/sheet1.xml"/></Relationships>)
    zip({ "xl/workbook.xml" => workbook, "xl/_rels/workbook.xml.rels" => relations, "xl/worksheets/sheet1.xml" => sheet, "xl/sharedStrings.xml" => shared })
  end

  def zip(files)
    buffer = Zip::OutputStream.write_buffer do |stream|
      files.each do |path, content|
        stream.put_next_entry(path)
        stream.write(content)
      end
    end
    buffer.string
  end

  def company = { name: "Société fictive SRL", vat: "BE0999999999" }

  def archive
    files = {
      "Societe_fictive_SRL_2026-050_900001.xml" => ubl(number: "2026-050", date: "2026-10-20", seller: company, buyer: { name: "Silvéa" }, net: "1000.00", vat: "210.00", item: "Maintenance fictive"),
      "Societe_fictive_SRL_2026-050_900001.pdf" => PDF,
      "Societe_fictive_SRL_900005_49668096_fictive_invoice_2026_051.xml" => ubl(number: "OKIOKI-900005", date: "2026-10-22", seller: company, buyer: { name: "Client français fictif", vat: "FR00999999999", country: "FR" }, net: "150.00", vat: "0.00", percent: 0),
      "20260815_900002_Facture_outil_fictif.xml" => ubl(number: "F-1", date: "2026-06-15", seller: { name: "Outil Fictif Inc.", country: "US" }, buyer: company, net: "12.00", vat: "0.00", currency: "USD", percent: 0),
      "20260815_900002_Facture_outil_fictif.pdf" => PDF,
      "20260620_900006_Autre_facture.xml" => ubl(number: "F-2", date: "2026-06-20", seller: { name: "OUTIL FICTIF INC", country: "US" }, buyer: company, net: "24.00", vat: "0.00", currency: "USD", percent: 0),
      "20261005_900003_Facture_belge.xml" => ubl(number: "B-7", date: "2026-10-05", seller: { name: "Fournisseur belge fictif", vat: "0123.456.789" }, buyer: company, net: "100.00", vat: "21.00"),
      "Societe_fictive_SRL_2026-099_900004_BE00000000000000_20261005_00010.xml" => ubl(number: "2026-099", date: "2026-10-05", seller: company, buyer: { name: "Banque fictive" }, net: "5000.00", vat: "0.00"),
      "Societe_fictive_SRL_2026-099_900004_BE00000000000000_20261005_00010.pdf" => PDF,
      "900007_0000000000_16_10_2026.pdf" => PDF
    }
    transactions = xlsx([
      [ Date.new(2026, 6, 16), -10.80, "-12.00 USD", "900002" ],
      [ Date.new(2026, 10, 25), 1210, nil, "900001" ],
      [ Date.new(2026, 10, 6), -121, nil, "900003" ]
    ])
    zip(files.merge("202610/transactions.xlsx" => transactions))
  end

  def file
    Tempfile.new([ "okioki", ".zip" ], binmode: true).tap do |tempfile|
      tempfile.write(archive)
      tempfile.flush
    end
  end
end
