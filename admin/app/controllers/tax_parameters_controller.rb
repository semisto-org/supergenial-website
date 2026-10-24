# Dated tax figures used by the tax projection. The accountant confirms them (one of her write rights).
class TaxParametersController < ApplicationController
  before_action :set_tax_parameter, only: %i[ edit update verify ]
  allow_read_only_writes only: :verify

  def index
    @tax_parameters = TaxParameter.ordered
  end

  def new
    source = TaxParameter.find_by(id: params[:from])
    @tax_parameter = TaxParameter.new(source&.slice(:key, :label, :source, :value)&.merge(valid_from: Date.current.next_year.beginning_of_year))
  end

  def create
    @tax_parameter = TaxParameter.new(tax_parameter_params)
    if @tax_parameter.save
      redirect_to tax_parameters_path, notice: "Paramètre ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tax_parameter.update(tax_parameter_params.merge(verified_at: nil))
      redirect_to tax_parameters_path, notice: "Paramètre mis à jour : à confirmer par la comptable."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def verify
    @tax_parameter.update!(verified_at: Time.current)
    redirect_to tax_parameters_path, notice: "#{@tax_parameter} confirmé."
  end

  private
    def set_tax_parameter
      @tax_parameter = TaxParameter.find(params[:id])
    end

    def tax_parameter_params
      params.expect(tax_parameter: %i[ key label value valid_from source notes ])
    end
end
