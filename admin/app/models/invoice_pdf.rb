require "prawn"
require "prawn/table"
require "rqrcode"

# Readable copy of a sales document, set in the typefaces of the Super Génial website (EB Garamond and Inter),
# with the robot of the site watering the total. The Peppol UBL stays the legal original.
class InvoicePdf
  include PdfBranding

  ROBOT = Rails.root.join("vendor/images/invoice-robot.png")
  ROBOT_WIDTH = 104
  QR_SIZE = 72

  def initialize(invoice)
    @invoice = invoice
    @seller = invoice.seller.presence || CompanyProfile.current.snapshot
    @buyer = invoice.buyer.presence || invoice.client.invoicing_snapshot
  end

  def filename = "#{@invoice.credit_note? ? 'note-de-credit' : 'facture'}-#{@invoice.number || 'brouillon'}.pdf"

  def render
    Prawn::Document.new(page_size: "A4", margin: MARGIN, info: { Title: title, Author: @seller["legal_name"].to_s, Creator: "Admin Super Génial" }) do |pdf|
      register_fonts(pdf)
      pdf.font "Inter", size: 9.5
      pdf.default_leading 1.5
      pdf.fill_color TEXT
      if draft?
        watermark(pdf)
        pdf.on_page_create { watermark(pdf) }
      end
      header(pdf, @invoice.kind_label)
      details(pdf)
      parties(pdf)
      lines(pdf)
      totals(pdf)
      payment(pdf)
      general_terms(pdf)
      footer(pdf)
    end.render
  end

  private
    def title = "#{@invoice.kind_label} #{@invoice.number || '(brouillon)'}"

    def draft? = @invoice.number.blank?

    def total = @invoice.subtotal + @invoice.vat_amount

    def iban = @seller["iban"].to_s.scan(/.{1,4}/).join(" ")

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

    def details(pdf)
      items = [ [ "Numéro", @invoice.number.presence || "Brouillon" ], [ "Date", date(@invoice.issued_on) ] ]
      if @invoice.invoice?
        items << [ "Échéance", @invoice.due_on ? date(@invoice.due_on) : "#{CompanyProfile.current.payment_terms_days} jours après émission" ]
      end
      items << [ "Facture créditée", "#{@invoice.credited_invoice.number} du #{date(@invoice.credited_invoice.issued_on)}" ] if @invoice.credited_invoice
      items << [ "Projet", @invoice.project.name ] if @invoice.project
      field_rows(pdf, items, width: pdf.bounds.width, size: 10, font: "Inter", min_width: 96)
      pdf.move_down 14
      pdf.stroke_color RULE
      pdf.line_width 0.5
      pdf.stroke_horizontal_rule
      pdf.move_down 26
    end

    def lines(pdf)
      header = [ "Description", "Quantité", "Prix unitaire", "TVA", "Total HTVA" ].map { |label| caps(label, color: INK) }
      rows = @invoice.lines.map do |line|
        period = line.period_start && line.period_end ? "\n<font size='8'>#{ink(MUTED)}#{date(line.period_start)} – #{date(line.period_end)}</color></font>" : ""
        [ "#{escape(line.description)}#{period}", "#{number(line.quantity)} #{escape(line.unit_label)}", unit_money(line.net_unit_price),
          @invoice.standard? ? "#{number(line.vat_rate)} %" : "–", money(line.net_amount) ]
      end
      pdf.table([ header, *rows ], header: true, width: pdf.bounds.width, column_widths: { 1 => 66, 2 => 78, 3 => 40, 4 => 80 },
                cell_style: { size: 9.5, padding: [ 9, 6 ], borders: [ :bottom ], border_width: 0.5, border_color: [ RULE ] * 4, inline_format: true, leading: 2 }) do |table|
        table.row(0).padding = [ 0, 6, 7, 6 ]
        table.row(0).border_color = [ INK ] * 4
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
      height = [ padding * 2 + 26 + sentence_height + 12 + field_lines * FIELD_HEIGHT + (field_lines - 1) * FIELD_GAP, qr ? QR_SIZE + padding * 2 : 0 ].max
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
      pdf.fill_color PAPER
      pdf.fill_rounded_rectangle [ left - 6, top + 6 ], QR_SIZE + 12, QR_SIZE + 12, 4
      pdf.fill_color INK
      modules.each_with_index do |row, y|
        row.each_with_index { |dark, x| pdf.fill_rectangle [ left + x * cell, top - y * cell ], cell + 0.05, cell + 0.05 if dark }
      end
      pdf.fill_color TEXT
    end

    # The general terms on a page of their own, in two columns, from the text frozen with the seller at issuing:
    # a "## N. Title" line starts an article, the other lines are its paragraphs. The type shrinks until they fit one page.
    def general_terms(pdf)
      blocks = terms_blocks
      return if blocks.empty?
      size = TERMS_SIZES.find { |candidate| terms_fit?(blocks, candidate) } || TERMS_SIZES.last
      pdf.start_new_page
      draw_terms(pdf, blocks, size)
    end

    TERMS_SIZES = [ 7.2, 7, 6.8, 6.6, 6.4, 6.2, 6, 5.8, 5.6 ].freeze

    def terms_blocks
      text = @seller["general_terms"].to_s.split(/^---NOTES---$/).first.to_s
      text.each_line.map(&:strip).reject { |line| line.blank? || line.start_with?("# ") || line == "Conditions générales" }
        .map { |line| line.start_with?("## ") ? [ :heading, line.delete_prefix("## ") ] : [ :paragraph, line ] }
    end

    # Typesets the terms on a scratch document of the same geometry and checks they stay on its first page.
    def terms_fit?(blocks, size)
      scratch = Prawn::Document.new(page_size: "A4", margin: MARGIN)
      register_fonts(scratch)
      scratch.default_leading 1.5
      draw_terms(scratch, blocks, size)
      scratch.page_count == 1
    end

    def draw_terms(pdf, blocks, size)
      pdf.font("Garamond", style: :italic, size: 24) { pdf.text "Conditions générales", color: INK }
      pdf.text caps("#{@seller['legal_name']} · applicables à tous nos devis, commandes et factures"), inline_format: true
      pdf.move_down 8
      pdf.stroke_color INK
      pdf.line_width 0.75
      pdf.stroke_horizontal_rule
      pdf.move_down 12
      pdf.column_box([ 0, pdf.cursor ], columns: 2, spacer: 20, width: pdf.bounds.width) do
        blocks.each_with_index do |(kind, line), index|
          if kind == :heading
            pdf.move_down size * 0.7 if index.positive?
            pdf.font("Inter", style: :bold, size: size + 0.3) { pdf.text line, color: INK }
            pdf.move_down 1.5
          else
            pdf.font("Inter", size:) { pdf.text line, color: TEXT, leading: size * 0.18 }
            pdf.move_down size * 0.35
          end
        end
      end
    end
end
