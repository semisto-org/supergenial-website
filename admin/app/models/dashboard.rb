# Les chiffres de l'onglet « Revenus » de l'ancienne Google Sheet, calculés.
class Dashboard
  attr_reader :year

  def initialize(year: Date.current.year)
    @year = year
  end

  def target = Rails.configuration.x.annual_target

  def invoiced = @invoiced ||= Invoice.counted.in_year(year).sum(:amount)

  def target_progress = target.zero? ? 0 : (invoiced / target * 100).round

  def unpaid_invoices = Invoice.unpaid.includes(:client).recent

  def fixed_costs = @fixed_costs ||= FixedCost.active.to_a

  def monthly_costs = fixed_costs.sum(&:monthly_amount)

  def monthly_forecast_costs = fixed_costs.sum(&:monthly_forecast)

  # Comme dans la Sheet : la marge se calcule sur les frais prévisionnels.
  def yearly_costs = monthly_forecast_costs * 12

  def gross_margin = invoiced - yearly_costs

  def monthly_salary = gross_margin / 12

  def recurring_contracts = @recurring_contracts ||= Contract.actif.includes(plan: :prices).to_a

  def recurring_revenue = recurring_contracts.sum(&:yearly_amount)

  # Avec les changements de prix des formules déjà programmés.
  def recurring_revenue_next_year = recurring_contracts.sum(&:revenue_over_next_year)

  def unbilled_by_client
    TimeEntry.a_facturer.includes(:client, :project).group_by(&:client)
      .map { |client, entries| { client:, hours: entries.sum(&:hours), amount: entries.sum(&:amount), since: entries.map(&:performed_on).min } }
      .sort_by { |row| -row[:amount] }
  end

  def draft_invoices = Invoice.draft.includes(:client).recent

  # Services must be invoiced by the 15th of the following month (Belgian VAT rule).
  def billing_deadlines(today = Date.current)
    TimeEntry.a_facturer.where(performed_on: ...today.beginning_of_month).includes(:client, :project).to_a
      .group_by { |entry| entry.performed_on.next_month.beginning_of_month + 14 }
      .map { |deadline, entries| { deadline:, late: deadline < today, amount: entries.sum(&:amount), clients: entries.map(&:client).uniq } }
      .sort_by { |row| row[:deadline] }
  end

  def purchases_to_review = PurchaseInvoice.to_review.count

  def bank_transactions_to_match = BankTransaction.unmatched.count

  # A monthly fixed cost with a known supplier should bring one invoice a month: the ones missing for last month.
  def missing_purchase_invoices(today = Date.current)
    month = today.prev_month.all_month
    received = PurchaseInvoice.issued_between(month).distinct.pluck(:supplier_id)
    FixedCost.active.where(period: "mensuel").where("amount > 0").where.not(supplier_id: [ nil, *received ]).includes(:supplier).order(:name)
  end

  def due_contracts(horizon = 30.days)
    Contract.due_by(Date.current + horizon).includes(:client, plan: :prices).by_due_date
  end

  def low_packs
    Pack.includes(:client, :time_entries).select { |pack| pack.time_entries.any? && pack.remaining_hours < 2 }
  end

  def renewals(horizon = 60.days)
    FixedCost.active.where(renews_on: Date.current..(Date.current + horizon)).order(:renews_on)
  end
end
