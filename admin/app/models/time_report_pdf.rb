# Time statement sent to a client: the detail of the hours worked over a period, in the look of the invoices.
class TimeReportPdf
  include PdfBranding

  ROBOT = InvoicePdf::ROBOT
  ROBOT_WIDTH = 96

  def initialize(report)
    @report = report
    @seller = CompanyProfile.current.snapshot
    @buyer = report.client.invoicing_snapshot
  end

  delegate :filename, to: :@report

  def render
    Prawn::Document.new(page_size: "A4", margin: MARGIN, info: { Title: title, Author: @seller["legal_name"].to_s, Creator: "Admin Super Génial" }) do |pdf|
      register_fonts(pdf)
      pdf.font "Inter", size: 9.5
      pdf.default_leading 1.5
      pdf.fill_color TEXT
      header(pdf, "Relevé d'heures")
      details(pdf)
      parties(pdf)
      if @report.empty?
        pdf.font("Garamond", style: :italic, size: 13) { pdf.text "Aucune prestation sur cette période.", color: MUTED }
      else
        entries(pdf)
        totals(pdf)
        project_summary(pdf)
        packs(pdf)
      end
      footer(pdf)
    end.render
  end

  private
    def title = "Relevé d'heures #{@report.client} #{period}"

    def period = "du #{date(@report.from)} au #{date(@report.to)}"

    def hours(value) = "#{number(value)} h"

    def details(pdf)
      items = [ [ "Période", "#{date(@report.from)} – #{date(@report.to)}" ], [ "Date", date(Date.current) ] ]
      items << [ "Projet", @report.project.name ] if @report.project
      field_rows(pdf, items, width: pdf.bounds.width, size: 10, font: "Inter", min_width: 96)
      pdf.move_down 14
      pdf.stroke_color RULE
      pdf.line_width 0.5
      pdf.stroke_horizontal_rule
      pdf.move_down 26
    end

    def columns
      [ [ "Date", 62 ], ([ "Projet", 104 ] if show_project?), [ "Description", nil ], [ "Durée", 52 ], ([ "Montant HTVA", 78 ] if @report.with_amounts?) ].compact
    end

    def show_project? = @report.project.nil? && @report.entries.any?(&:project)

    def entries(pdf)
      header = columns.map { |label, _| caps(label, color: INK) }
      rows = @report.entries.map do |entry|
        description = escape(entry.description.presence || "Prestation")
        description += "\n<font size='8'>#{ink(MUTED)}#{escape(note(entry))}</color></font>" if note(entry)
        [ date(entry.performed_on), (escape(entry.project&.name) if show_project?), description, hours(entry.hours),
          (amount_cell(entry) if @report.with_amounts?) ].compact
      end
      widths = columns.each_with_index.filter_map { |(_, width), index| [ index, width ] if width }.to_h
      last = columns.size - 1
      pdf.table([ header, *rows ], header: true, width: pdf.bounds.width, column_widths: widths,
                cell_style: { size: 9.5, padding: [ 8, 6 ], borders: [ :bottom ], border_width: 0.5, border_color: [ RULE ] * 4, inline_format: true, leading: 2 }) do |table|
        table.row(0).padding = [ 0, 6, 7, 6 ]
        table.row(0).border_color = [ INK ] * 4
        table.row(0).border_width = 0.75
        table.column(0).padding_left = 0
        table.column(last).padding_right = 0
        table.columns((columns.index { |label, _| label == "Durée" })..last).align = :right
      end
    end

    # Hours that will not be billed by the hour say why, so the client is never surprised.
    def note(entry)
      if entry.au_pack? then "Déduit du pack « #{entry.pack.label} »"
      elsif entry.offert? then "Offert"
      end
    end

    def amount_cell(entry) = @report.billable?(entry) ? money(entry.amount) : "–"

    def totals(pdf)
      robot_height = ROBOT_WIDTH * 283.0 / 325
      pdf.start_new_page if pdf.cursor < robot_height + 60
      pdf.move_down 20
      top = pdf.cursor
      width = 214
      pdf.image ROBOT.to_s, at: [ pdf.bounds.width - width - ROBOT_WIDTH - 26, top - 4 ], width: ROBOT_WIDTH
      pdf.bounding_box([ pdf.bounds.width - width, top ], width:) do
        rows = [ [ "Prestations", @report.entries.size.to_s ] ]
        rows << [ "Dont offertes", hours(@report.offered_hours) ] if @report.offered_hours.positive?
        rows << [ "Montant HTVA", money(@report.total_amount) ] if @report.with_amounts?
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
          pdf.text caps("Total des heures", color: INK), inline_format: true
        end
        pdf.font("Garamond", style: :bold, size: 25) { pdf.text hours(@report.total_hours), color: INK, align: :right }
      end
      pdf.move_cursor_to [ pdf.cursor, top - robot_height - 4 ].min
    end

    def project_summary(pdf)
      return unless @report.several_projects?
      rows = @report.project_totals.map { |project, total| [ escape(project&.name || "Sans projet"), hours(total) ] }
      section(pdf, "Par projet", [ [ "Projet", "Durée" ], *rows ])
    end

    # Prepaid packs drawn on during the period, with their balance today.
    def packs(pdf)
      return if @report.packs.empty?
      rows = @report.packs.map do |pack|
        used = @report.entries.select { |entry| entry.pack_id == pack.id }.sum(&:hours)
        [ escape(pack.label), hours(pack.hours), hours(used), hours(pack.remaining_hours) ]
      end
      section(pdf, "Packs d'heures", [ [ "Pack", "Acheté", "Sur la période", "Solde au #{date(Date.current)}" ], *rows ])
    end

    def section(pdf, heading, (labels, *rows))
      pdf.start_new_page if pdf.cursor < 60 + rows.size * 24
      pdf.move_down 26
      pdf.font("Garamond", style: :italic, size: 17) { pdf.text heading, color: INK }
      pdf.move_down 6
      pdf.table([ labels.map { |label| caps(label, color: INK) }, *rows ], header: true, width: pdf.bounds.width,
                cell_style: { size: 9.5, padding: [ 7, 6 ], borders: [ :bottom ], border_width: 0.5, border_color: [ RULE ] * 4, inline_format: true }) do |table|
        table.row(0).padding = [ 0, 6, 7, 6 ]
        table.row(0).border_color = [ INK ] * 4
        table.row(0).border_width = 0.75
        table.column(0).padding_left = 0
        table.column(labels.size - 1).padding_right = 0
        table.columns(1..(labels.size - 1)).align = :right if labels.size > 1
      end
    end
end
