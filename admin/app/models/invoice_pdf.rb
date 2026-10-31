require "prawn"
require "prawn/table"
require "rqrcode"

# Readable copy of a sales document, set in the typefaces of the Super Génial website (EB Garamond and Inter),
# with the robot of the site watering the total. The Peppol UBL stays the legal original.
class InvoicePdf
  INK = "2A1A48"
  ACCENT = "7B4FC9"
  TEXT = "2E2A38"
  MUTED = "7A7489"
  RULE = "E3DCEF"
  TINT = "F6F2FC"
  WATERMARK = "F1EBFA"
  FONTS = Rails.root.join("vendor/fonts")
  ROBOT = Rails.root.join("vendor/images/invoice-robot.png")
  ROBOT_WIDTH = 104
  QR_SIZE = 72
  FIELD_HEIGHT = 28
  FIELD_GAP = 10

  def initialize(invoice)
    @invoice = invoice
    @seller = invoice.seller.presence || CompanyProfile.current.snapshot
    @buyer = invoice.buyer.presence || invoice.client.invoicing_snapshot
  end

  def filename = "#{@invoice.credit_note? ? 'note-de-credit' : 'facture'}-#{@invoice.number || 'brouillon'}.pdf"

  def render
    Prawn::Document.new(page_size: "A4", margin: [ 60, 56, 86, 56 ], info: { Title: title, Author: @seller["legal_name"].to_s, Creator: "Admin Super Génial" }) do |pdf|
      register_fonts(pdf)
      pdf.font "Inter", size: 9.5
      pdf.default_leading 1.5
      pdf.fill_color TEXT
      if draft?
        watermark(pdf)
        pdf.on_page_create { watermark(pdf) }
      end
      header(pdf)
      details(pdf)
      parties(pdf)
      lines(pdf)
      totals(pdf)
      payment(pdf)
      footer(pdf)
    end.render
  end

  private
    def title = "#{@invoice.kind_label} #{@invoice.number || '(brouillon)'}"

    def draft? = @invoice.number.blank?

    def total = @invoice.subtotal + @invoice.vat_amount

    def money(value) = ActiveSupport::NumberHelper.number_to_currency(value, unit: "€", format: "%n %u", separator: ",", delimiter: " ")

    def number(value) = ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2, strip_insignificant_zeros: true, separator: ",")

    def date(value) = value && I18n.l(value)

    def iban = @seller["iban"].to_s.scan(/.{1,4}/).join(" ")

    # Prawn's inline format only knows &amp;, &lt; and &gt;.
    def escape(text) = text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")

    # A small spaced-out uppercase label, as inline format markup.
    def caps(text, color: MUTED) = "<font name='Inter Medium' size='6.5' character_spacing='1.2'><color rgb='#{color}'>#{escape(text.upcase)}</color></font>"

    def register_fonts(pdf)
      pdf.font_families.update(
        "Garamond" => { normal: font_file("EBGaramond-Regular"), italic: font_file("EBGaramond-Italic"),
                        bold: font_file("EBGaramond-Medium"), bold_italic: font_file("EBGaramond-MediumItalic") },
        "Inter" => { normal: font_file("Inter-Regular"), italic: font_file("Inter-Italic"), bold: font_file("Inter-SemiBold") },
        "Inter Medium" => { normal: font_file("Inter-Medium") }
      )
    end

    # Labelled values side by side, each column as wide as its value; a value that does not fit starts a new row.
    def field_rows(pdf, fields, width:, size:, font:, min_width: 0)
      pack_fields(pdf, fields, width:, size:, font:, min_width:).each_with_index do |row, index|
        pdf.move_down FIELD_GAP if index.positive?
        cells = row.map { |(label, value), _| "#{caps(label)}\n<font name='#{font}' size='#{size}'><color rgb='#{INK}'>#{escape(value)}</color></font>" }
        pdf.table([ cells ], column_widths: row.map { |_, column| [ column, width ].min }, cell_style: { borders: [], padding: 0, inline_format: true, leading: 3 })
      end
    end

    def pack_fields(pdf, fields, width:, size:, font:, min_width: 0)
      rows = [ [] ]
      fields.each do |field|
        column = [ text_width(pdf, field.last, font:, size:) + 26, min_width ].max
        rows << [] if rows.last.any? && rows.last.sum(&:last) + column > width
        rows.last << [ field, column ]
      end
      rows
    end

    def text_width(pdf, text, font:, size:)
      width = nil
      pdf.font(font, size:) { width = pdf.width_of(text.to_s) }
      width
    end

    def font_file(name) = FONTS.join("#{name}.ttf").to_s

    # A draft must never pass for the real thing: a large pale word sits behind the content of every page.
    def watermark(pdf)
      pdf.canvas do
        pdf.rotate(32, origin: [ pdf.bounds.width / 2, pdf.bounds.height / 2 ]) do
          pdf.font("Garamond", style: :italic, size: 150) do
            pdf.fill_color WATERMARK
            pdf.text_box "Brouillon", at: [ -200, pdf.bounds.height / 2 + 90 ], width: pdf.bounds.width + 400, height: 200, align: :center
            pdf.fill_color TEXT
          end
        end
      end
    end

    def header(pdf)
      top = pdf.cursor
      pdf.formatted_text [ { text: "Super ", font: "Garamond", styles: [ :bold ], size: 34, color: INK },
                           { text: "Génial", font: "Garamond", styles: [ :bold, :italic ], size: 34, color: ACCENT } ]
      pdf.bounding_box([ pdf.bounds.width - 240, top ], width: 240) do
        pdf.font("Garamond", style: :italic, size: 34) { pdf.text @invoice.kind_label, color: INK, align: :right }
        reference = draft? ? caps("Brouillon · non émis", color: ACCENT) : "#{caps('N°')}  <font name='Inter Medium' size='11'><color rgb='#{INK}'>#{escape(@invoice.number)}</color></font>"
        pdf.text reference, inline_format: true, align: :right
      end
      pdf.move_down 26
      pdf.stroke_color INK
      pdf.line_width 0.75
      pdf.stroke_horizontal_rule
      pdf.move_down 14
    end

    def details(pdf)
      items = [ [ "Date", date(@invoice.issued_on) ] ]
      if @invoice.invoice?
        items << [ "Échéance", @invoice.due_on ? date(@invoice.due_on) : "#{CompanyProfile.current.payment_terms_days} jours après émission" ]
      end
      items << [ "Communication", @invoice.structured_reference ] if @invoice.invoice? && @invoice.structured_reference.present?
      items << [ "Facture créditée", "#{@invoice.credited_invoice.number} du #{date(@invoice.credited_invoice.issued_on)}" ] if @invoice.credited_invoice
      items << [ "Projet", @invoice.project.name ] if @invoice.project
      field_rows(pdf, items, width: pdf.bounds.width, size: 10, font: "Inter", min_width: 96)
      pdf.move_down 14
      pdf.stroke_color RULE
      pdf.line_width 0.5
      pdf.stroke_horizontal_rule
      pdf.move_down 26
    end

    def parties(pdf)
      seller = [ @seller["street"], [ @seller["postal_code"], @seller["city"] ].compact_blank.join(" "),
                 ("TVA #{@seller['vat_number']}" if @seller["vat_number"].present?), @seller["email"] ].compact_blank
      buyer = [ @buyer["street"], [ @buyer["postal_code"], @buyer["city"] ].compact_blank.join(" "),
                Country.name(@buyer["country"]), ("TVA #{@buyer['vat_number']}" if @buyer["vat_number"].present?) ].compact_blank
      cells = [ [ "De", @seller["legal_name"], seller ], [ "Pour", @buyer["name"], buyer ] ].map do |label, name, address|
        "#{caps(label)}\n<font name='Garamond' size='16'><b><color rgb='#{INK}'>#{escape(name)}</color></b></font>\n" \
          "<font size='9'>#{address.map { |line| escape(line) }.join("\n")}</font>"
      end
      half = pdf.bounds.width / 2
      pdf.table([ cells ], column_widths: [ half, half ], cell_style: { borders: [], padding: [ 0, 18, 0, 0 ], inline_format: true, leading: 2.5 })
      pdf.move_down 34
    end

    def lines(pdf)
      header = [ "Description", "Quantité", "Prix unitaire", "TVA", "Total HTVA" ].map { |label| caps(label, color: INK) }
      rows = @invoice.lines.map do |line|
        period = line.period_start && line.period_end ? "\n<font size='8'><color rgb='#{MUTED}'>#{date(line.period_start)} – #{date(line.period_end)}</color></font>" : ""
        [ "#{escape(line.description)}#{period}", "#{number(line.quantity)} #{escape(line.unit_label)}", money(line.unit_price),
          @invoice.standard? ? "#{number(line.vat_rate)} %" : "–", money(line.net_amount) ]
      end
      pdf.table([ header, *rows ], header: true, width: pdf.bounds.width, column_widths: { 1 => 66, 2 => 78, 3 => 40, 4 => 80 },
                cell_style: { size: 9.5, padding: [ 9, 6 ], borders: [ :bottom ], border_width: 0.5, border_color: RULE, inline_format: true, leading: 2 }) do |table|
        table.row(0).padding = [ 0, 6, 7, 6 ]
        table.row(0).border_color = INK
        table.row(0).border_width = 0.75
        table.columns(1..4).align = :right
        table.column(0).padding_left = 0
        table.column(4).padding_right = 0
        table.column(4).font_style = :bold
      end
    end

    # The robot waters the totals: it stands on the left, the amounts to pay sit on the right.
    def totals(pdf)
      robot_height = ROBOT_WIDTH * 283.0 / 325
      pdf.start_new_page if pdf.cursor < robot_height + 60
      pdf.move_down 20
      top = pdf.cursor
      width = 214
      pdf.image ROBOT.to_s, at: [ pdf.bounds.width - width - ROBOT_WIDTH - 26, top - 4 ], width: ROBOT_WIDTH
      pdf.bounding_box([ pdf.bounds.width - width, top ], width:) do
        rows = [ [ "Total HTVA", money(@invoice.subtotal) ] ]
        @invoice.vat_subtotals.each { |subtotal| rows << [ "TVA #{number(subtotal[:rate])} % sur #{money(subtotal[:taxable])}", money(subtotal[:vat]) ] } if @invoice.standard?
        rows.each do |label, value|
          pdf.float { pdf.text label, color: MUTED }
          pdf.text value, align: :right
          pdf.move_down 4
        end
        pdf.move_down 4
        pdf.stroke_color INK
        pdf.line_width 0.75
        pdf.stroke_horizontal_rule
        pdf.move_down 8
        pdf.float do
          pdf.move_down 10
          pdf.text caps(@invoice.credit_note? ? "Total à rembourser" : "Total à payer", color: INK), inline_format: true
        end
        pdf.font("Garamond", style: :bold, size: 25) { pdf.text money(total), color: INK, align: :right }
      end
      pdf.move_cursor_to [ pdf.cursor, top - robot_height - 4 ].min
      if (mention = @invoice.regime[:mention])
        pdf.move_down 12
        pdf.font("Garamond", style: :italic, size: 11) { pdf.text mention, color: TEXT }
      end
    end

    # Bank details on a soft panel, with a QR code banking apps read (EPC "Girocode") once the invoice is issued.
    def payment(pdf)
      return unless @invoice.invoice? && @seller["iban"].present?
      qr = payment_qr
      padding = 18
      inner = pdf.bounds.width - padding * 2 - (qr ? QR_SIZE + 28 : 0)
      sentence = payment_sentence
      fields = [ [ "IBAN", iban ], ([ "Communication", @invoice.structured_reference ] if @invoice.structured_reference.present?), ([ "BIC", @seller["bic"] ] if @seller["bic"].present?) ].compact
      field_lines = pack_fields(pdf, fields, width: inner, size: 10.5, font: "Inter Medium").size
      sentence_height = pdf.height_of_formatted(Prawn::Text::Formatted::Parser.format(sentence), width: inner)
      height = [ padding * 2 + 26 + sentence_height + 12 + field_lines * FIELD_HEIGHT + (field_lines - 1) * FIELD_GAP, qr ? QR_SIZE + padding * 2 + 14 : 0 ].max
      pdf.move_down 30
      pdf.start_new_page if pdf.cursor < height
      top = pdf.cursor
      pdf.fill_color TINT
      pdf.fill_rounded_rectangle [ 0, top ], pdf.bounds.width, height, 6
      pdf.fill_color TEXT
      pdf.bounding_box([ padding, top - padding ], width: inner) do
        pdf.font("Garamond", style: :italic, size: 17) { pdf.text "Paiement", color: INK }
        pdf.move_down 4
        pdf.text sentence, inline_format: true
        pdf.move_down 12
        field_rows(pdf, fields, width: inner, size: 10.5, font: "Inter Medium")
      end
      draw_qr(pdf, qr, [ pdf.bounds.width - padding - QR_SIZE, top - padding ]) if qr
      pdf.move_cursor_to top - height
    end

    # A draft has no due date nor structured communication yet: say so rather than leave blanks in the sentence.
    def payment_sentence
      return "Le numéro de facture, l'échéance et la communication structurée seront attribués à l'émission." if draft?
      due = @invoice.due_on ? " avant le <b>#{date(@invoice.due_on)}</b>" : ""
      "Merci de verser <b>#{money(total)}</b>#{due} sur le compte ci-dessous#{', avec la communication structurée' if @invoice.structured_reference.present?}."
    end

    # EPC069-12 payload. Belgian banking apps read the structured communication from the remittance text.
    def payment_qr
      return if draft? || !total.positive?
      payload = [ "BCD", "002", "1", "SCT", @seller["bic"].to_s, @seller["legal_name"].to_s.first(70), @seller["iban"].to_s,
                  format("EUR%.2f", total), "", "", @invoice.structured_reference.presence || @invoice.number ].join("\n")
      RQRCode::QRCode.new(payload, level: :m)
    end

    def draw_qr(pdf, qr, (left, top))
      modules = qr.modules
      cell = QR_SIZE.to_f / modules.size
      pdf.fill_color "FFFFFF"
      pdf.fill_rounded_rectangle [ left - 6, top + 6 ], QR_SIZE + 12, QR_SIZE + 12, 4
      pdf.fill_color INK
      modules.each_with_index do |row, y|
        row.each_with_index { |dark, x| pdf.fill_rectangle [ left + x * cell, top - y * cell ], cell + 0.05, cell + 0.05 if dark }
      end
      pdf.fill_color TEXT
      pdf.text_box caps("Scanner pour payer"), at: [ left - 10, top - QR_SIZE - 12 ], width: QR_SIZE + 20, align: :center, inline_format: true
    end

    def footer(pdf)
      identity = [ @seller["legal_name"], ("BCE #{@seller['enterprise_number']}" if @seller["enterprise_number"].present?),
                   ("TVA #{@seller['vat_number']}" if @seller["vat_number"].present?), @seller["email"], @seller["website"] ].compact_blank.join("  ·  ")
      text = [ identity, @seller["invoice_footer"] ].compact_blank.join("\n")
      pdf.repeat(:all) do
        pdf.bounding_box([ 0, pdf.bounds.bottom - 22 ], width: pdf.bounds.width, height: 44) do
          pdf.stroke_color RULE
          pdf.line_width 0.5
          pdf.stroke_horizontal_rule
          pdf.move_down 8
          pdf.font("Inter", size: 7) { pdf.text text, color: MUTED, align: :center, leading: 2 }
        end
      end
      return if pdf.page_count < 2
      pdf.font("Inter", size: 7) do
        pdf.number_pages "<page> / <total>", at: [ pdf.bounds.width - 60, pdf.bounds.bottom - 46 ], width: 60, align: :right, color: MUTED
      end
    end
end
