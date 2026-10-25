class ContractsController < ApplicationController
  before_action :set_contract, only: %i[ show edit update destroy bill ]

  def index
    @kind = params[:kind].presence_in(Contract::KINDS.keys)
    @contracts = Contract.includes(:client, plan: :prices).by_due_date
    @contracts = @kind ? @contracts.of_kind(@kind) : @contracts
    @contracts = params[:all] ? @contracts : @contracts.actif
  end

  def show
  end

  def new
    plan = Plan.find_by(id: params[:plan_id])
    @contract = Contract.new(client_id: preselected_client_id, plan:, label: plan&.name,
                             kinds: [ params[:kind].presence_in(Contract::KINDS.keys) || (plan ? "maintenance" : "hebergement") ],
                             period: plan&.period || "annuel", starts_on: Date.current, next_billing_on: Date.current)
  end

  def create
    @contract = Contract.new(contract_params)
    if @contract.save
      redirect_to @contract, notice: "Contrat créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contract.update(contract_params)
      redirect_to @contract, notice: "Contrat mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contract.destroy
    redirect_to contracts_path, notice: "Contrat supprimé.", status: :see_other
  end

  def bill
    invoice = @contract.bill!(on: params[:issued_on].presence&.to_date || Date.current)
    redirect_to invoice, notice: "#{@contract} : brouillon de #{helpers.eur(invoice.amount)} créé, prochaine échéance le #{l(@contract.next_billing_on)}."
  end

  private
    def set_contract
      @contract = Contract.find(params[:id])
    end

    def contract_params
      params.expect(contract: [ :client_id, :project_id, :fixed_cost_id, :plan_id, :label, :amount, :cost, :period,
                                  :starts_on, :next_billing_on, :status, :registrar, :notes, kinds: [] ])
    end
end
