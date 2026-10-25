class AdminMcp::Overview::GetDashboard < AdminMcp::Tool
  S = AdminMcp::Serializer

  description "Yearly overview: revenue invoiced vs annual target, fixed costs, margin, recurring revenue, " \
              "unpaid invoices, unbilled hours per client, contracts due within 30 days, packs running low, " \
              "fixed costs renewing within 60 days."
  read_only!
  input_schema(properties: { year: { type: "integer", description: "Defaults to the current year." } })

  class << self
    private
      def perform(year: nil)
        dashboard = ::Dashboard.new(year: year || Date.current.year)
        {
          year: dashboard.year, annual_target: S.money(dashboard.target), invoiced: S.money(dashboard.invoiced),
          target_progress_percent: dashboard.target_progress,
          monthly_fixed_costs: S.money(dashboard.monthly_costs), monthly_forecast_costs: S.money(dashboard.monthly_forecast_costs),
          gross_margin: S.money(dashboard.gross_margin), monthly_salary: S.money(dashboard.monthly_salary),
          recurring_revenue: S.money(dashboard.recurring_revenue), recurring_revenue_next_year: S.money(dashboard.recurring_revenue_next_year),
          unpaid_invoices: dashboard.unpaid_invoices.map { |invoice| S.invoice(invoice) },
          unbilled_by_client: dashboard.unbilled_by_client.map { |row|
            { client_id: row[:client].id, client_name: row[:client].name, hours: row[:hours].to_f, amount: S.money(row[:amount]), since: row[:since] }
          },
          due_contracts: dashboard.due_contracts.map { |contract| S.contract(contract) },
          low_packs: dashboard.low_packs.map { |pack| S.pack(pack).merge(client_name: pack.client.name) },
          renewals: dashboard.renewals.map { |cost| S.fixed_cost(cost) }
        }
      end
  end
end
