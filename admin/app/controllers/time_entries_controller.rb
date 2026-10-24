class TimeEntriesController < ApplicationController
  before_action :set_time_entry, only: %i[ edit update destroy ]

  def index
    @filters = params.permit(:client_id, :status).to_h.compact_blank
    @filters[:status] ||= "a_facturer" unless params.key?(:status)
    @time_entries = TimeEntry.recent.includes(:client, :project, :pack).where(@filters).limit(300)
    @time_entry = TimeEntry.new(performed_on: Date.current, client_id: @filters[:client_id])
  end

  def new
    @time_entry = TimeEntry.new(performed_on: Date.current, client_id: preselected_client_id, project_id: params[:project_id])
  end

  def create
    @time_entry = TimeEntry.new(time_entry_params)
    if @time_entry.save
      redirect_back_or_to time_entries_path, notice: "#{helpers.hours(@time_entry.hours)} ajoutées pour #{@time_entry.client}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @time_entry.update(time_entry_params)
      redirect_to time_entries_path(client_id: @time_entry.client_id), notice: "Prestation mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @time_entry.destroy
    redirect_back_or_to time_entries_path, notice: "Prestation supprimée.", status: :see_other
  end

  # Regroupe les heures cochées d'un même client dans un brouillon de facture.
  def bill
    invoice = TimeEntry.bill!(TimeEntry.a_facturer.where(id: params[:ids]).includes(:client, :project))
    redirect_to invoice, notice: "Brouillon de #{helpers.eur(invoice.amount)} créé pour #{invoice.client} : vérifie-le, puis émets-le."
  rescue ArgumentError => error
    redirect_to time_entries_path, alert: error.message
  end

  private
    def set_time_entry
      @time_entry = TimeEntry.find(params[:id])
    end

    def time_entry_params
      params.expect(time_entry: %i[ client_id project_id pack_id performed_on description hours km location status ])
    end
end
