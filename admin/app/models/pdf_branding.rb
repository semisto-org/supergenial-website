require "prawn"
require "prawn/table"

# Shared look of the printed documents (invoices, time reports): black ink only, the typefaces of the website,
# the brand lettering in the header and the seller identity in the footer. Includers set @seller and @buyer (snapshots).
module PdfBranding
  # Black ink only, as CMYK tints of K, so that printing never uses colour cartridges.
  INK = [ 0, 0, 0, 100 ]
  TEXT = [ 0, 0, 0, 92 ]
  MUTED = [ 0, 0, 0, 58 ]
  RULE = [ 0, 0, 0, 18 ]
  TINT = [ 0, 0, 0, 5 ]
  WATERMARK = [ 0, 0, 0, 6 ]
  PAPER = [ 0, 0, 0, 0 ]
  FONTS = Rails.root.join("vendor/fonts")
  LOGO = Rails.root.join("vendor/images/supergenial-logo.svg")
  LOGO_HEIGHT = 30
  MARGIN = [ 60, 56, 86, 56 ].freeze
  FIELD_HEIGHT = 28
  FIELD_GAP = 10

  private
    def money(value) = ActiveSupport::NumberHelper.number_to_currency(value, unit: "€", format: "%n %u", separator: ",", delimiter: " ")

    def number(value) = ActiveSupport::NumberHelper.number_to_rounded(value, precision: 2, strip_insignificant_zeros: true, separator: ",")

    def date(value) = value && I18n.l(value)

    # Prawn's inline format only knows &amp;, &lt; and &gt;.
    def escape(text) = text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")

    # A small spaced-out uppercase label, as inline format markup.
    # Opening inline-format tag for a black tint; closed by </color>.
    def ink(color) = "<color c='0' m='0' y='0' k='#{color.last}'>"

    def caps(text, color: MUTED) = "<font name='Inter Medium' size='6.5' character_spacing='1.2'>#{ink(color)}#{escape(text.upcase)}</color></font>"

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
        cells = row.map { |(label, value), _| "#{caps(label)}\n<font name='#{font}' size='#{size}'>#{ink(INK)}#{escape(value)}</color></font>" }
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

    # The brand lettering is a single filled SVG path (absolute M, L, H, V, Q and Z commands, with implicit repeats), drawn as
    # vector shapes in black ink so that it prints as sharply as the text.
    def logo(pdf, at:, height:)
      svg = File.read(LOGO)
      min_x, min_y, _width, view_height = svg[/viewBox="([^"]+)"/, 1].split.map(&:to_f)
      scale = height / view_height
      left, top = at
      point = ->(x, y) { [ left + (x - min_x) * scale, top - (y - min_y) * scale ] }

      pdf.fill_color INK
      current = start = [ 0.0, 0.0 ]
      svg[/ d="([^"]+)"/, 1].scan(/([MLHVQZ])([^MLHVQZ]*)/) do |command, args|
        numbers = args.scan(/-?\d*\.?\d+(?:e-?\d+)?/i).map(&:to_f)
        case command
        when "M", "L"
          numbers.each_slice(2).with_index do |target, index|
            current = target
            if command == "M" && index.zero?
              start = target
              pdf.move_to(*point.(*target))
            else
              pdf.line_to(*point.(*target))
            end
          end
        when "H" then numbers.each { |x| current = [ x, current[1] ]; pdf.line_to(*point.(*current)) }
        when "V" then numbers.each { |y| current = [ current[0], y ]; pdf.line_to(*point.(*current)) }
        when "Q"
          numbers.each_slice(4) do |cx, cy, x, y|
            control, target = [ cx, cy ], [ x, y ]
            first = current.zip(control).map { |from, via| from + 2.0 / 3 * (via - from) }
            second = target.zip(control).map { |to, via| to + 2.0 / 3 * (via - to) }
            pdf.curve_to(point.(*target), bounds: [ point.(*first), point.(*second) ])
            current = target
          end
        when "Z" then pdf.close_path; current = start
        end
      end
      pdf.fill
      pdf.fill_color TEXT
    end

    def header(pdf, title)
      top = pdf.cursor
      logo(pdf, at: [ 0, top - 8 ], height: LOGO_HEIGHT)
      pdf.bounding_box([ pdf.bounds.width - 240, top ], width: 240) do
        pdf.font("Garamond", style: :italic, size: 34) { pdf.text title, color: INK, align: :right }
      end
      pdf.move_down 18
      pdf.stroke_color INK
      pdf.line_width 0.75
      pdf.stroke_horizontal_rule
      pdf.move_down 14
    end

    def parties(pdf)
      seller = [ @seller["street"], [ @seller["postal_code"], @seller["city"] ].compact_blank.join(" "),
                 ("TVA #{@seller['vat_number']}" if @seller["vat_number"].present?) ].compact_blank
      buyer = [ @buyer["street"], [ @buyer["postal_code"], @buyer["city"] ].compact_blank.join(" "),
                Country.name(@buyer["country"]), ("TVA #{@buyer['vat_number']}" if @buyer["vat_number"].present?) ].compact_blank
      cells = [ [ "De", @seller["legal_name"], seller ], [ "Pour", @buyer["name"], buyer ] ].map do |label, name, address|
        "#{caps(label)}\n<font name='Garamond' size='16'><b>#{ink(INK)}#{escape(name)}</color></b></font>\n" \
          "<font size='9'>#{address.map { |line| escape(line) }.join("\n")}</font>"
      end
      half = pdf.bounds.width / 2
      pdf.table([ cells ], column_widths: [ half, half ], cell_style: { borders: [], padding: [ 0, 18, 0, 0 ], inline_format: true, leading: 2.5 })
      pdf.move_down 34
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
