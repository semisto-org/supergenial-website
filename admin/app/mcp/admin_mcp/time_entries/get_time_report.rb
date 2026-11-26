class AdminMcp::TimeEntries::GetTimeReport < AdminMcp::Tool
  description "Time statement of one client over a period, meant to be sent to the client: every entry whatever its " \
              "billing status, totals, and pdf_url, the printable PDF (opens in the admin, behind its login). " \
              "Period defaults to the previous calendar month. with_amounts adds the value of the hours billed by the hour."
  read_only!
  input_schema(properties: {
    client_id: { type: "integer" },
    from: { type: "string", format: "date" },
    to: { type: "string", format: "date" },
    project_id: { type: "integer", description: "Only this project of the client." },
    with_amounts: { type: "boolean", description: "Defaults to false: the PDF shows hours only." }
  }, required: [ "client_id" ])

  class << self
    private
      def perform(client_id:, from: nil, to: nil, project_id: nil, with_amounts: false)
        client = find(Client, client_id)
        default_from, default_to = TimeReport.default_period
        report = TimeReport.new(client:, from: parse_date(from, "from") || default_from, to: parse_date(to, "to") || default_to,
                                project: project_id && find(Project, project_id), with_amounts:)
        { client_id: client.id, client_name: client.name, from: report.from, to: report.to, project_id: report.project&.id,
          total_hours: report.total_hours.to_f, offered_hours: report.offered_hours.to_f,
          total_amount: (AdminMcp::Serializer.money(report.total_amount) if with_amounts),
          time_entries: report.entries.map { |entry| AdminMcp::Serializer.time_entry(entry) },
          pdf_url: pdf_url(report) }.compact
      end

      def pdf_url(report)
        options = Rails.application.config.action_mailer.default_url_options.to_h
        options[:protocol] = "https" if Rails.env.production?
        Rails.application.routes.url_helpers.client_time_report_url(
          report.client, **options, from: report.from.iso8601, to: report.to.iso8601,
          project_id: report.project&.id, amounts: ("1" if report.with_amounts?)
        )
      end
  end
end
