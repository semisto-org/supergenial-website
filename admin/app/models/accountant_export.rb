require "zip"

# Everything the accountant imports for a quarter, in one zip: sales and purchase UBL (Peppol originals)
# and PDFs, the CODA bank statements, the Intervat files and a summary of the grids.
class AccountantExport
  def initialize(vat_return)
    @vat_return = vat_return
  end

  def filename = "super-genial-#{@vat_return.quarter.year}-T#{@vat_return.quarter.quarter}.zip"

  def render
    buffer = Zip::OutputStream.write_buffer do |zip|
      @vat_return.invoices.each { |invoice| add_sale(zip, invoice) }
      @vat_return.purchase_invoices.each { |purchase| add_purchase(zip, purchase) }
      BankStatement.where(statement_on: @vat_return.quarter.range).includes(file_attachment: :blob).find_each do |statement|
        add(zip, "banque/#{statement.statement_on.iso8601}-#{statement.number}.cod", statement.file.download) if statement.file.attached?
      end
      xml = IntervatXml.new(@vat_return)
      add(zip, xml.filename("intervat"), xml.declaration)
      add(zip, xml.filename("listing-intracom"), xml.intracom_listing) if @vat_return.intracom_listing.any?
      add(zip, "grilles.csv", grids_csv)
      add(zip, "achats.csv", purchases_csv)
    end
    buffer.string
  end

  private
    def add(zip, path, content)
      zip.put_next_entry(path)
      zip.write(content)
    end

    def add_sale(zip, invoice)
      name = "ventes/#{invoice.number.presence || "sans-numero-#{invoice.id}"}"
      add(zip, "#{name}.xml", invoice.ubl_xml) if invoice.ubl_xml.present?
      add(zip, "#{name}.pdf", InvoicePdf.new(invoice).render) if invoice.admin?
    end

    def add_purchase(zip, purchase)
      name = "achats/#{purchase.id}-#{purchase.to_s.parameterize}"
      add(zip, "#{name}.xml", purchase.ubl_xml) if purchase.ubl_xml.present?
      add(zip, "#{name}#{File.extname(purchase.document.filename.to_s)}", purchase.document.download) if purchase.document.attached?
    end

    def grids_csv
      CSV.generate(col_sep: ";") do |csv|
        csv << %w[ grille montant ]
        @vat_return.grids.each { |grid, amount| csv << [ grid, format("%.2f", amount).tr(".", ",") ] }
      end
    end

    def purchases_csv
      CSV.generate(col_sep: ";") do |csv|
        csv << %w[ id fournisseur tva_fournisseur numero date type categorie compte htva tva regime tva_autoliquidee tva_deductible payee_le ]
        @vat_return.purchase_invoices.each do |purchase|
          csv << [ purchase.id, purchase.supplier&.name || purchase.seller_name, purchase.supplier&.vat_number, purchase.number, purchase.issued_on, purchase.kind_label,
                   purchase.expense_category&.name, purchase.expense_category&.pcmn_account, money(purchase.amount), money(purchase.vat_amount),
                   purchase.vat_regime_label, money(purchase.self_assessed_vat), money(purchase.deductible_vat), purchase.paid_on ]
        end
      end
    end

    def money(value) = format("%.2f", value.to_d).tr(".", ",")
end
