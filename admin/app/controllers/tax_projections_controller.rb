class TaxProjectionsController < ApplicationController
  def show
    @year = params[:year].to_i.nonzero? || Date.current.year
    @projection = TaxProjection.new(year: @year)
    @parameters = TaxParameter.in_force(on: Date.new(@year, 12, 31))
  end

  def update
    plan = FiscalPlan.for(params[:year].to_i.nonzero? || Date.current.year)
    if plan.update(params.expect(fiscal_plan: %i[ monthly_remuneration year_end_remuneration plci_amount notes ]))
      redirect_to tax_projection_path(year: plan.year), notice: "Plan #{plan.year} mis à jour."
    else
      redirect_to tax_projection_path(year: plan.year), alert: plan.errors.full_messages.to_sentence
    end
  end
end
