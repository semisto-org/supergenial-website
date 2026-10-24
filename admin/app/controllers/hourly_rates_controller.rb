class HourlyRatesController < ApplicationController
  def index
    @rates = HourlyRate.chronological
    @rate = HourlyRate.new
  end

  def create
    rate = HourlyRate.new(params.expect(hourly_rate: %i[ amount starts_on ]))
    if rate.save
      redirect_to hourly_rates_path, notice: "#{helpers.eur(rate.amount)}/h à partir du #{l(rate.starts_on)}."
    else
      redirect_to hourly_rates_path, alert: rate.errors.full_messages.to_sentence
    end
  end

  def destroy
    if HourlyRate.count > 1
      HourlyRate.find(params[:id]).destroy
      redirect_to hourly_rates_path, notice: "Taux supprimé.", status: :see_other
    else
      redirect_to hourly_rates_path, alert: "Il faut garder au moins un taux.", status: :see_other
    end
  end
end
