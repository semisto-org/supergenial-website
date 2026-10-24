require "prawn"
require "prawn/table"

# Readable copy of a sales document in the Super Génial colours. The Peppol UBL stays the legal original.
class InvoicePdf
  PLUM = "3C3956"
  ACCENT = "7B4FC9"
  MUTED = "595959"
  SOFT = "EEE8DA"
  FONTS = Rails.root.join("vendor/fonts")

  def initialize(invoice)
    @invoice = invoice
    @seller = invoice.seller.presence || CompanyProfile.current.snapshot
    @buyer = invoice.buyer.presence || invoice.client.invoicing_snapshot
  end

  def filename = "#{@invoice.credit_note? ? 'note-de-credit' : 'facture'}-#{@invoice.number || 'brouillon'}.pdf"

  def render
    Prawn::Document.new(page_size: "A4", margin: [ 48, 48, 60, 48 ], info: { Title: title, Creator: "Admin Super Génial" }) do |pdf|
      pdf.font_families.update("Liberation Sans" => { normal: FONTS.join("LiberationSans-Regular.ttf").to_s, bold: FONTS.join("LiberationSans-Bold.ttf").to_s,
                                                     italic: FONTS.join("LiberationSans-Italic.ttf").to_s })
      pdf.font "Liberation Sans", size: 10
      header(pdf)
      parties(pdf)
      lines(pdf)
      totals(pdf)
      payment(pdf)
      footer(pdf)
    end.render
  end

  private
    def title = "#{@invoice.kind_label} #{@invoice.number || '(brouillon)'}"

    def money(value) = ActiveSupport::NumberHelper.number_to_currency(value, unit: "€", format: "%n %u", separator: ",", delimiter: " ")

    def number(value) = ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2, strip_insignificant_zeros: true, separator: ",")

    def date(value) = value && I18n.l(value)

    def header(pdf)
      pdf.fill_color PLUM
      pdf.text "Super <color rgb='#{ACCENT}'><i>Génial</i></color>", size: 26, style: :bold, inline_format: true
      pdf.fill_color MUTED
      pdf.text @seller["legal_name"].to_s, size: 9
      pdf.move_down 18
      pdf.fill_color PLUM
      pdf.text title, size: 18, style: :bold
      pdf.fill_color "1A1A1A"
      details = [ [ "Date", date(@invoice.issued_on) ] ]
      details << [ "Échéance", date(@invoice.due_on) ] if @invoice.due_on
      details << [ "Facture créditée", "#{@invoice.credited_invoice.number} du #{date(@invoice.credited_invoice.issued_on)}" ] if @invoice.credited_invoice
      details << [ "Projet", @invoice.project.name ] if @invoice.project
      pdf.table(details, cell_style: { borders: [], padding: [ 1, 12, 1, 0 ], size: 9 }) { |table| table.column(0).text_color = MUTED }
      pdf.move_down 18
    end

    def parties(pdf)
      seller = [ @seller["legal_name"], @seller["street"], [ @seller["postal_code"], @seller["city"] ].compact_blank.join(" "),
                 ("TVA #{@seller['vat_number']}" if @seller["vat_number"].present?), @seller["email"] ].compact_blank
      buyer = [ @buyer["name"], @buyer["street"], [ @buyer["postal_code"], @buyer["city"] ].compact_blank.join(" "),
                Country.name(@buyer["country"]), ("TVA #{@buyer['vat_number']}" if @buyer["vat_number"].present?) ].compact_blank
      pdf.table([ [ "De", "Pour" ], [ seller.join("\n"), buyer.join("\n") ] ], width: pdf.bounds.width,
                cell_style: { borders: [], padding: [ 2, 12, 2, 0 ], size: 9 }) do |table|
        table.row(0).text_color = MUTED
        table.row(0).font_style = :bold
      end
      pdf.move_down 20
    end

    def lines(pdf)
      rows = [ [ "Description", "Quantité", "Prix unitaire", "TVA", "Total HTVA" ] ]
      @invoice.lines.each do |line|
        period = line.period_start && line.period_end ? "\n#{date(line.period_start)} – #{date(line.period_end)}" : ""
        rows << [ "#{line.description}#{period}", "#{number(line.quantity)} #{line.unit_label}", money(line.unit_price),
                  @invoice.standard? ? "#{number(line.vat_rate)} %" : "–", money(line.net_amount) ]
      end
      pdf.table(rows, header: true, width: pdf.bounds.width, column_widths: { 1 => 70, 2 => 80, 3 => 45, 4 => 80 },
                cell_style: { size: 9, padding: [ 5, 6 ], borders: [ :bottom ], border_color: "E4DCCB" }) do |table|
        table.row(0).background_color = SOFT
        table.row(0).font_style = :bold
        table.row(0).text_color = PLUM
        table.columns(1..4).align = :right
      end
    end

    def totals(pdf)
      rows = [ [ "Total HTVA", money(@invoice.subtotal) ] ]
      @invoice.vat_subtotals.each { |subtotal| rows << [ "TVA #{number(subtotal[:rate])} % sur #{money(subtotal[:taxable])}", money(subtotal[:vat]) ] } if @invoice.standard?
      rows << [ @invoice.credit_note? ? "Total à rembourser" : "Total à payer", money(@invoice.subtotal + @invoice.vat_amount) ]
      pdf.move_down 10
      pdf.table(rows, position: :right, column_widths: [ 200, 90 ], cell_style: { borders: [], size: 10, padding: [ 3, 6 ] }) do |table|
        table.column(1).align = :right
        table.row(-1).font_style = :bold
        table.row(-1).text_color = PLUM
        table.row(-1).background_color = SOFT
      end
      if (mention = @invoice.regime[:mention])
        pdf.move_down 10
        pdf.text mention, size: 9, style: :italic
      end
    end

    def payment(pdf)
      return unless @invoice.invoice?
      pdf.move_down 18
      pdf.fill_color PLUM
      pdf.text "Paiement", style: :bold
      pdf.fill_color "1A1A1A"
      pdf.text "Merci de verser #{money(@invoice.subtotal + @invoice.vat_amount)} avant le #{date(@invoice.due_on)} sur le compte " \
               "#{@seller['iban']}#{" (BIC #{@seller['bic']})" if @seller['bic'].present?}, avec la communication structurée " \
               "<b>#{@invoice.structured_reference}</b>.", inline_format: true, size: 9
    end

    def footer(pdf)
      text = [ [ @seller["legal_name"], ("BCE #{@seller['enterprise_number']}" if @seller["enterprise_number"].present?) ].compact.join(" · "),
               @seller["invoice_footer"] ].compact_blank.join("\n")
      pdf.repeat(:all) do
        pdf.bounding_box([ 0, pdf.bounds.bottom - 10 ], width: pdf.bounds.width, height: 40) do
          pdf.fill_color MUTED
          pdf.text text, size: 7.5, align: :center
        end
      end
    end
end
