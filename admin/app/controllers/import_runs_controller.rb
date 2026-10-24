# History imports: Harvest through its API (in the background), OkiOki from a CSV export (right away).
class ImportRunsController < ApplicationController
  MAX_CSV_SIZE = 5.megabytes

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
      return redirect_to(import_runs_path, alert: "Choisis le fichier CSV exporté d'OkiOki.") unless file.respond_to?(:read)
      return redirect_to(import_runs_path, alert: "Fichier trop lourd (5 Mo maximum).") if file.size > MAX_CSV_SIZE

      run = ImportRun.create!(kind: "okioki", dry_run: dry_run?, filename: file.original_filename, options: { replace_unnumbered: params[:replace_unnumbered] == "1" })
      HistoryImportJob.perform_now(run, file.read)
      redirect_to run
    end
end
