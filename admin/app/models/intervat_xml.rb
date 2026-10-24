require "builder"

# XML files to import into Intervat (SPF Finances): the periodic VAT return (VATConsignment)
# and the intra-EU customer listing (IntraConsignment). Amounts with two decimals, grids without leading zero.
class IntervatXml
  INPUT_COMMON = "http://www.minfin.fgov.be/InputCommon"

  def initialize(vat_return, company: CompanyProfile.current)
    @vat_return, @company = vat_return, company
  end

  def declaration
    xml = builder
    xml.VATConsignment(xmlns: "http://www.minfin.fgov.be/VATConsignment", "xmlns:ns2": INPUT_COMMON, VATDeclarationsNbr: "1") do
      xml.VATDeclaration(SequenceNumber: "1", DeclarantReference: reference("TVA")) do
        declarant(xml)
        period(xml)
        xml.Data do
          @vat_return.grids.each { |grid, amount| xml.Amount(decimal(amount), GridNumber: grid.to_i.to_s) }
        end
        xml.ClientListingNihil(@vat_return.intracom_listing.empty? ? "YES" : "NO")
        xml.Ask(Restitution: "NO", Payment: "NO")
      end
    end
    xml.target!
  end

  def intracom_listing
    rows = @vat_return.intracom_listing
    total = rows.sum { |row| row["amount"].to_d }
    xml = builder
    xml.IntraConsignment(xmlns: "http://www.minfin.fgov.be/IntraConsignment", "xmlns:ns2": INPUT_COMMON, IntraListingsNbr: "1") do
      xml.IntraListing(SequenceNumber: "1", ClientsNbr: rows.size.to_s, DeclarantReference: reference("LIC"), AmountSum: decimal(total)) do
        declarant(xml)
        period(xml)
        rows.each.with_index(1) do |row, index|
          xml.IntraClient(SequenceNumber: index.to_s) do
            xml.CompanyVATNumber(row["vat_number"][2..], issuedBy: row["vat_number"][0, 2])
            xml.Code(row["code"])
            xml.Amount(decimal(row["amount"]))
          end
        end
      end
    end
    xml.target!
  end

  def filename(kind) = "#{kind}-#{@vat_return.quarter.year}-T#{@vat_return.quarter.quarter}.xml"

  private
    def builder
      xml = Builder::XmlMarkup.new
      xml.instruct!(:xml, version: "1.0", encoding: "UTF-8")
      xml
    end

    def declarant(xml)
      xml.Declarant do
        xml.tag!("ns2:VATNumber", @company.enterprise_number)
        xml.tag!("ns2:Name", @company.legal_name)
        xml.tag!("ns2:Street", @company.street)
        xml.tag!("ns2:PostCode", @company.postal_code)
        xml.tag!("ns2:City", @company.city)
        xml.tag!("ns2:CountryCode", @company.country)
        xml.tag!("ns2:EmailAddress", @company.email)
        xml.tag!("ns2:Phone", @company.phone.to_s.gsub(/[^\d+]/, ""))
      end
    end

    def period(xml)
      xml.Period do
        xml.Quarter(@vat_return.quarter.quarter.to_s)
        xml.Year(@vat_return.quarter.year.to_s)
      end
    end

    def reference(prefix) = "#{prefix}#{@vat_return.quarter.year}T#{@vat_return.quarter.quarter}"

    def decimal(value) = format("%.2f", value.to_d)
end
