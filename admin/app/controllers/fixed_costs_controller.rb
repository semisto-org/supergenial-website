class FixedCostsController < ApplicationController
  before_action :set_fixed_cost, only: %i[ edit update destroy ]

  def index
    @fixed_costs = FixedCost.order(:category, :name)
    @active = @fixed_costs.select(&:active?)
  end

  def new
    @fixed_cost = FixedCost.new
  end

  def create
    @fixed_cost = FixedCost.new(fixed_cost_params)
    if @fixed_cost.save
      redirect_to fixed_costs_path, notice: "Frais ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @fixed_cost.update(fixed_cost_params)
      redirect_to fixed_costs_path, notice: "Frais mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @fixed_cost.destroy
    redirect_to fixed_costs_path, notice: "Frais supprimé.", status: :see_other
  end

  private
    def set_fixed_cost
      @fixed_cost = FixedCost.find(params[:id])
    end

    def fixed_cost_params
      params.expect(fixed_cost: %i[ name category supplier_id amount period forecast_amount renews_on action billing_url active notes ])
    end
end
