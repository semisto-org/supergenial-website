# Projects the company's taxable result and corporate tax for a year, and what to do before December 31:
# the reduced rate (20 % on the first 100 000 €) needs a manager's remuneration of at least 45 000 €,
# or at least the taxable profit. Figures are estimates to discuss with the accountant, not a tax return.
class TaxProjection
  ADVANCE_PAYMENT_DAYS = [ [ 4, 10 ], [ 7, 10 ], [ 10, 10 ], [ 12, 20 ] ].freeze

  attr_reader :year, :today

  def initialize(year: Date.current.year, today: Date.current, plan: FiscalPlan.for(year))
    @year, @today, @plan = year, today, plan
  end

  def plan = @plan

  def parameter(key) = TaxParameter.value(key, on: Date.new(year, 12, 31))

  def year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

  # Whole months still to come this year (all twelve for a future year, none for a past one).
  def remaining_months
    return 12 if today.year < year
    return 0 if today.year > year
    12 - today.month
  end

  def revenue_to_date = @revenue_to_date ||= Invoice.counted.in_year(year).sum(:amount)

  def recurring_revenue_ahead = Contract.actif.to_a.sum { |contract| contract.yearly_amount / 12 } * remaining_months

  def unbilled_work = TimeEntry.a_facturer.where(performed_on: year_range).to_a.sum(&:amount)

  def revenue = revenue_to_date + recurring_revenue_ahead + unbilled_work

  # Purchases count for their tax-deductible share (restaurants, gifts… are only partly deductible).
  def costs_to_date
    @costs_to_date ||= PurchaseInvoice.issued_between(year_range).includes(:expense_category).sum do |purchase|
      purchase.sign * purchase.amount * (purchase.expense_category&.tax_deductible_percent || 100) / 100
    end
  end

  def fixed_costs_ahead = FixedCost.active.to_a.sum(&:monthly_forecast) * remaining_months

  def costs = costs_to_date + fixed_costs_ahead

  def bank_total(category) = -BankTransaction.where(category:, booked_on: year_range).sum(:amount)

  def remuneration_paid = bank_total("remuneration")

  def remuneration_planned = plan.monthly_remuneration * remaining_months + plan.year_end_remuneration

  def remuneration = remuneration_paid + remuneration_planned

  # Social contributions paid by the company, or estimated on the remuneration when none were paid yet.
  def social_contributions
    paid = bank_total("social")
    estimate = [ remuneration, parameter(:social_contribution_ceiling) ].min * parameter(:social_contribution_rate) / 100
    [ paid, estimate ].max
  end

  def plci = plan.plci_amount

  def taxable_profit = [ revenue - costs - remuneration - social_contributions - plci, 0 ].max

  def reduced_rate? = taxable_profit.zero? || remuneration >= [ parameter(:director_min_remuneration), taxable_profit ].min

  def corporate_tax
    profit = taxable_profit
    if reduced_rate?
      reduced = [ profit, parameter(:isoc_reduced_ceiling) ].min
      reduced * parameter(:isoc_reduced_rate) / 100 + (profit - reduced) * parameter(:isoc_standard_rate) / 100
    else
      profit * parameter(:isoc_standard_rate) / 100
    end.round(2)
  end

  # Extra remuneration that keeps the reduced rate: up to 45 000 €, or until it reaches the profit,
  # knowing that each euro paid also lowers the profit (with its social contributions).
  def remuneration_needed
    return 0 if reduced_rate?
    to_minimum = parameter(:director_min_remuneration) - remuneration
    social_rate = parameter(:social_contribution_rate) / 100
    to_profit = (revenue - costs - social_contributions - plci - 2 * remuneration) / (2 + social_rate)
    [ to_minimum, to_profit ].min.clamp(0..).round(2)
  end

  def advance_payments = ADVANCE_PAYMENT_DAYS.map { |month, day| Date.new(year, month, day) }

  def advance_paid = bank_total("taxes")

  # Paying a quarter of the tax at each due date avoids the surcharge.
  def advance_payment_schedule
    share = (corporate_tax / 4).round(2)
    advance_payments.map.with_index(1) { |due_on, index| { due_on:, amount: share, cumulated: share * index } }
  end

  def next_advance_payment = advance_payment_schedule.find { |payment| payment[:due_on] >= today }

  def advance_shortfall
    due = advance_payment_schedule.select { |payment| payment[:due_on] < today }.sum { |payment| payment[:amount] }
    [ due - advance_paid, 0 ].max
  end

  # From November on, the last weeks to act on the remuneration.
  def year_end_alert? = today.year == year && today.month >= 11 && remuneration_needed.positive?
end
