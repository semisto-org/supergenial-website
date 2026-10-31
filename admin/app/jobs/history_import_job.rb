class HistoryImportJob < ApplicationJob
  queue_as :default

  def perform(import_run, csv = nil)
    import_run.update!(status: "running")
    Current.user = import_run.user
    importer = case import_run.kind
    when "harvest"
      HarvestImport.new(time_entries_until: import_run.options["time_entries_until"].presence&.to_date, dry_run: import_run.dry_run)
    when "okioki"
      options = { replace_unnumbered: import_run.options["replace_unnumbered"], dry_run: import_run.dry_run }
      if import_run.file.attached?
        return import_run.file.open { |archive| finish(import_run, OkiokiArchiveImport.new(archive.path, **options)) }
      end
      OkiokiImport.new(csv, **options)
    end
    finish(import_run, importer)
  rescue StandardError => error
    import_run.update!(status: "failed", error: error.message, finished_at: Time.current)
    Rails.error.report(error, handled: true)
  end

  private
    def finish(import_run, importer)
      import_run.update!(status: "done", report: importer.run, finished_at: Time.current)
    end
end
