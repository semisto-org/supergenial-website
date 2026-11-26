# PDF statement of the hours worked for one client over a period, to send to the client.
class TimeReportsController < ApplicationController
  def show
    client = Client.find(params[:client_id])
    default_from, default_to = TimeReport.default_period
    report = TimeReport.new(client:, from: parse_date(params[:from]) || default_from, to: parse_date(params[:to]) || default_to,
                            project: params[:project_id].presence && client.projects.find(params[:project_id]),
                            with_amounts: params[:amounts] == "1")
    document = TimeReportPdf.new(report)
    send_data document.render, filename: document.filename, type: "application/pdf", disposition: params[:download] ? "attachment" : "inline"
  rescue ArgumentError => error
    redirect_to client, alert: error.message
  end

  private
    def parse_date(value)
      value.presence && Date.iso8601(value)
    rescue Date::Error
      raise ArgumentError, "Date invalide : #{value}"
    end
end
