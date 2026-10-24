class ClientsController < ApplicationController
  before_action :set_client, only: %i[ show edit update destroy verify_peppol ]

  def index
    @status = params[:status].presence_in(Client::STATUSES.keys)
    @clients = Client.alphabetical.includes(:contacts)
    @clients = @clients.where(status: @status) if @status
  end

  def show
    @time_entries = @client.time_entries.recent.includes(:project, :pack).limit(30)
  end

  def new
    @client = Client.new
  end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to @client, notice: "Client créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: "Client mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @client.destroy
      redirect_to clients_path, notice: "#{@client} supprimé.", status: :see_other
    else
      redirect_to @client, status: :see_other,
        alert: "Impossible de supprimer #{@client} : #{helpers.pluralize(@client.invoices.count, "facture")} y #{@client.invoices.many? ? "sont liées" : "est liée"}. " \
               "Passe-le en « Ancien client », ou supprime d'abord ses factures."
    end
  end

  # Looks the client up in the Peppol network through Recommand and keeps the result.
  def verify_peppol
    address = @client.suggested_peppol_id
    return redirect_to(@client, alert: "Renseigne un n° de TVA belge ou un identifiant Peppol.") if address.blank?

    result = Recommand::Client.new.verify(address)
    @client.update!(peppol_reachable: result["isValid"], peppol_checked_at: Time.current, peppol_id: result["isValid"] ? address : @client.peppol_id)
    redirect_to @client, notice: result["isValid"] ? "#{address} reçoit les factures Peppol." : "#{address} n'est pas joignable sur Peppol."
  rescue Recommand::Error, KeyError => error
    redirect_to @client, alert: error.is_a?(KeyError) ? "Recommand n'est pas configuré (variables RECOMMAND_* dans Coolify)." : error.message
  end

  private
    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.expect(client: %i[ name kind status vat_number street postal_code city country billing_email peppol_id address hourly_rate notes ])
    end
end
