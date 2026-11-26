require "test_helper"

class TimeReportsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "client page offers the statement and the pdf renders" do
    get client_path(clients(:dici))
    assert_select "form[action='#{client_time_report_path(clients(:dici))}']"

    get client_time_report_path(clients(:dici), from: "2026-10-01", to: "2026-10-31", amounts: "1")
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.headers["Content-Disposition"], "releve-heures-#{clients(:dici).name.parameterize}-2026-10-01-2026-10-31.pdf"
  end

  test "an empty period still renders, a reversed one goes back to the client" do
    get client_time_report_path(clients(:dici), from: "2020-01-01", to: "2020-01-31")
    assert_equal "application/pdf", response.media_type

    get client_time_report_path(clients(:dici), from: "2026-10-31", to: "2026-10-01")
    assert_redirected_to client_path(clients(:dici))
  end

  test "report totals every status and values only hours billed by the hour" do
    client = clients(:silvea)
    client.time_entries.create!(performed_on: "2026-07-09", hours: 1, description: "Geste", status: "offert")
    client.time_entries.create!(performed_on: "2026-07-10", hours: 2, description: "Extra")
    report = TimeReport.new(client:, from: Date.new(2026, 7, 1), to: Date.new(2026, 7, 31), with_amounts: true)

    assert_equal [ 12, 1 ], [ report.total_hours, report.offered_hours ]
    assert_equal 2 * client.rate(Date.new(2026, 7, 10)), report.total_amount
    assert_equal [ packs(:silvea_10h) ], report.packs
    assert TimeReportPdf.new(report).render.start_with?("%PDF")
  end

  test "a project of another client is refused" do
    assert_raises(ArgumentError) do
      TimeReport.new(client: clients(:silvea), from: Date.new(2026, 1, 1), to: Date.new(2026, 12, 31), project: projects(:platform))
    end
  end
end
