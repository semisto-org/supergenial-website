require "test_helper"

class ImportRunsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "upload an OkiOki export" do
    get import_runs_path
    assert_response :success

    file = Rack::Test::UploadedFile.new(StringIO.new(OkiokiImportTest::CSV_TEXT), "text/csv", original_filename: "okioki.csv")
    post import_runs_path, params: { kind: "okioki", file:, dry_run: "0", replace_unnumbered: "1" }
    run = ImportRun.last
    assert_redirected_to import_run_path(run)
    assert run.done?, run.error
    assert Invoice.exists?(number: "2026-041")

    get import_run_path(run)
    assert_response :success
  end

  test "harvest needs its variables" do
    post import_runs_path, params: { kind: "harvest" }
    assert_redirected_to import_runs_path
  end

  test "the accountant cannot import" do
    sign_in_as users(:accountant)
    get import_runs_path
    assert_redirected_to root_path
  end
end
