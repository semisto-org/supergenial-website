# Time statement sent to a client: the detail of the hours worked over a period, in the look of the invoices
# but set tight, so that a busy month fits on few pages (about 40 entries a page).
class TimeReportPdf
  include PdfBranding

  SIZE = 8.5
  ROW_PADDING = [ 3.5, 5 ].freeze

  def initialize(report)
    @report = report
    @seller = CompanyProfile.current.snapshot
    @buyer = report.client.invoicing_snapshot
  end

  delegate :filename, to: :@report

  def render
    Prawn::Document.new(page_size: "A4", margin: MARGIN, info: { Title: title, Author: @seller["legal_name"].to_s, Creator: "Admin Super Génial" }) do |pdf|
      register_fonts(pdf)
      pdf.font "Inter", size: SIZE
      pdf.default_leading 1
      pdf.fill_color TEXT
      heading(pdf)
      if @report.empty?
        pdf.font("Garamond", style: :italic, size: 12) { pdf.text "Aucune prestation sur cette période.", color: MUTED }
      else
        entries(pdf)
        totals(pdf)
        summaries(pdf)
      end
      footer(pdf)
    end.render
  end

  private
    def title = "Relevé d'heures #{@report.client} #{period}"

    def period = "du #{date(@report.from)} au #{date(@report.to)}"

    def hours(value) = "#{number(value)} h"

    # Logo and title on one line, then client, period and date as a single row of fields: no address blocks,
    # the seller identity already sits in the footer.
    def heading(pdf)
      top = pdf.cursor
      logo(pdf, at: [ 0, top - 4 ], height: 20)
      pdf.bounding_box([ pdf.bounds.width - 240, top ], width: 240) do
        pdf.font("Garamond", style: :italic, size: 24) { pdf.text "Relevé d'heures", color: INK, align: :right }
      end
      pdf.move_down 8
      pdf.stroke_color INK
      pdf.line_width 0.75
      pdf.stroke_horizontal_rule
      pdf.move_down 10
      items = [ [ "Client", @report.client.name ], [ "Période", "#{date(@report.from)} – #{date(@report.to)}" ] ]
      items << [ "Projet", @report.project.name ] if @report.project
      items << [ "Émis le", date(Date.current) ]
      field_rows(pdf, items, width: pdf.bounds.width, size: 9.5, font: "Inter", min_width: 80)
      pdf.move_down 16
    end

    def columns
      [ [ "Date", 64 ], ([ "Projet", 100 ] if show_project?), [ "Description", nil ], [ "Durée", 44 ], ([ "Montant HTVA", 70 ] if @report.with_amounts?) ].compact
    end

    def show_project? = @report.project.nil? && @report.entries.any?(&:project)

    # Over several months, each month opens with its name and subtotal; the rows below stay in date order.
    def entries(pdf)
      header = columns.map { |label, _| caps(label, color: INK) }
      months = @report.entries.group_by { |entry| entry.performed_on.beginning_of_month }
      rows = months.flat_map do |month, entries|
        next entries.map { |entry| entry_row(entry) } if months.one?
        [ month_row(month, entries), *entries.map { |entry| entry_row(entry) } ]
      end
      month_rows = rows.each_index.select { |index| rows[index].first.is_a?(Hash) }.map { |index| index + 1 }
      compact_table(pdf, [ header, *rows ], widths: columns.each_with_index.filter_map { |(_, width), index| [ index, width ] if width }.to_h,
                    right_from: columns.index { |label, _| label == "Durée" }) do |table|
        month_rows.each do |index|
          table.row(index).padding = [ index == 1 ? 6 : 12, 5, 3, 5 ]
          table.row(index).border_color = [ INK ] * 4
          table.row(index).column(0).padding_left = 0
          table.row(index).column(-1).padding_right = 0
        end
      end
    end

    def entry_row(entry)
      description = escape(entry.description.presence || "Prestation")
      description += "  #{ink(MUTED)}· #{escape(note(entry))}</color>" if note(entry)
      [ date(entry.performed_on), (escape(entry.project&.name) if show_project?), description, hours(entry.hours),
        (amount_cell(entry) if @report.with_amounts?) ].compact
    end

    # The month name spans the columns before the duration; its subtotals sit under the duration and amount.
    def month_row(month, entries)
      name = I18n.l(month, format: "%B %Y").capitalize
      span = columns.index { |label, _| label == "Durée" }
      [ { content: "<font name='Garamond' size='12'><i>#{ink(INK)}#{escape(name)}</color></i></font>", colspan: span },
        "<b>#{ink(INK)}#{hours(entries.sum(&:hours))}</color></b>",
        ("<b>#{ink(INK)}#{money(entries.sum { |entry| @report.amount(entry) })}</color></b>" if @report.with_amounts?) ].compact
    end

    # Hours that will not be billed by the hour say why, so the client is never surprised.
    def note(entry)
      if entry.au_pack? then "pack « #{entry.pack.label} »"
      elsif entry.offert? then "offert"
      end
    end

    def amount_cell(entry) = @report.billable?(entry) ? money(entry.amount) : "–"

    # A single closing line under the table: details on the left, the total in large type on the right.
    def totals(pdf)
      pdf.start_new_page if pdf.cursor < 40
      pdf.move_down 8
      top = pdf.cursor
      details = [ "#{@report.entries.size} prestations" ]
      details << "dont #{hours(@report.offered_hours)} offertes" if @report.offered_hours.positive?
      details << "#{money(@report.total_amount)} HTVA" if @report.with_amounts?
      pdf.bounding_box([ 0, top ], width: pdf.bounds.width - 200) do
        pdf.move_down 8
        pdf.text details.join("  ·  "), color: MUTED
      end
      pdf.bounding_box([ pdf.bounds.width - 200, top ], width: 200) do
        pdf.float do
          pdf.move_down 9
          pdf.text caps("Total des heures", color: INK), inline_format: true
        end
        pdf.font("Garamond", style: :bold, size: 20) { pdf.text hours(@report.total_hours), color: INK, align: :right }
      end
    end

    # Hours per project and prepaid packs side by side, when there is something to say.
    def summaries(pdf)
      tables = []
      if @report.several_projects?
        rows = @report.project_totals.map { |project, total| [ escape(project&.name || "Sans projet"), hours(total) ] }
        tables << [ "Par projet", [ [ "Projet", "Durée" ], *rows ] ]
      end
      if @report.packs.any?
        rows = @report.packs.map do |pack|
          used = @report.entries.select { |entry| entry.pack_id == pack.id }.sum(&:hours)
          [ escape(pack.label), hours(pack.hours), hours(used), hours(pack.remaining_hours) ]
        end
        tables << [ "Packs d'heures", [ [ "Pack", "Acheté", "Période", "Solde au #{date(Date.current)}" ], *rows ] ]
      end
      return if tables.empty?

      height = 40 + tables.map { |_, (_, *rows)| rows.size }.max * 16
      pdf.start_new_page if pdf.cursor < height
      pdf.move_down 18
      gap = 24
      width = tables.one? ? pdf.bounds.width : (pdf.bounds.width - gap) / 2
      top = pdf.cursor
      bottom = top
      tables.each_with_index do |(heading, (labels, *rows)), index|
        pdf.bounding_box([ index * (width + gap), top ], width:) do
          pdf.font("Garamond", style: :italic, size: 13) { pdf.text heading, color: INK }
          pdf.move_down 3
          compact_table(pdf, [ labels.map { |label| caps(label, color: INK) }, *rows ], right_from: 1)
        end
        bottom = [ bottom, pdf.cursor ].min
      end
      pdf.move_cursor_to bottom
    end

    def compact_table(pdf, data, right_from:, widths: {}, &)
      last = data.first.size - 1
      pdf.table(data, header: true, width: pdf.bounds.width, column_widths: widths,
                cell_style: { size: SIZE, padding: ROW_PADDING, borders: [ :bottom ], border_width: 0.4, border_color: [ RULE ] * 4, inline_format: true, leading: 1 }) do |table|
        table.row(0).padding = [ 0, 5, 5, 5 ]
        table.row(0).border_color = [ INK ] * 4
        table.row(0).border_width = 0.75
        table.column(0).padding_left = 0
        table.column(last).padding_right = 0
        table.columns(right_from..last).align = :right if right_from && right_from <= last
        yield table if block_given?
      end
    end
end
