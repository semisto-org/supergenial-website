# History imports: Harvest through its API and the OkiOki ZIP archive (in the background),
# an OkiOki CSV export (right away).
class ImportRunsController < ApplicationController
  MAX_CSV_SIZE = 5.megabytes
  MAX_ARCHIVE_SIZE = 200.megabytes

  require_admin

  def index
    @import_runs = ImportRun.recent.limit(30)
    @harvest_configured = HarvestImport::Api.configured?
  end

  def show
    @import_run = ImportRun.find(params[:id])
  end

  def create
    case params[:kind]
    when "harvest" then import_harvest
    when "okioki" then import_okioki
    else head :unprocessable_entity
    end
  end

  private
    def dry_run? = params[:dry_run] == "1"

    def import_harvest
      return redirect_to(import_runs_path, alert: "Harvest n'est pas configuré (variables HARVEST_* dans Coolify).") unless HarvestImport::Api.configured?
      run = ImportRun.create!(kind: "harvest", dry_run: dry_run?, options: { time_entries_until: params[:time_entries_until].presence })
      HistoryImportJob.perform_later(run)
      redirect_to run, notice: "Import Harvest lancé : cette page se met à jour quand il est terminé."
    end

    def import_okioki
      file = params[:file]
      return redirect_to(import_runs_path, alert: "Choisis le ZIP ou le CSV exporté d'OkiOki.") unless file.respond_to?(:read)

      options = { replace_unnumbered: params[:replace_unnumbered] == "1" }
      if archive?(file)
        return redirect_to(import_runs_path, alert: "Archive trop lourde (200 Mo maximum).") if file.size > MAX_ARCHIVE_SIZE
        run = ImportRun.create!(kind: "okioki", dry_run: dry_run?, filename: file.original_filename, options:, file:)
        HistoryImportJob.perform_later(run)
        redirect_to run, notice: "Import de l'archive OkiOki lancé : cette page se met à jour quand il est terminé."
      else
        return redirect_to(import_runs_path, alert: "Fichier trop lourd (5 Mo maximum).") if file.size > MAX_CSV_SIZE
        run = ImportRun.create!(kind: "okioki", dry_run: dry_run?, filename: file.original_filename, options:)
        HistoryImportJob.perform_now(run, file.read)
        redirect_to run
      end
    end

    def archive?(file)
      signature = file.read(2)
      file.rewind
      signature == "PK"
    end
end
