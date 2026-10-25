class AdminMcp::FixedCosts::ListFixedCosts < AdminMcp::Tool
  description "List Super Génial's fixed costs (tools, servers, subscriptions) with monthly amounts, forecast after " \
              "planned changes, and renewal dates."
  read_only!
  input_schema(properties: { active_only: { type: "boolean", description: "Defaults to true." },
                             category: { type: "string", enum: FixedCost::CATEGORIES.keys } })

  class << self
    private
      def perform(active_only: true, category: nil)
        costs = FixedCost.order(:category, :name)
        costs = costs.active if active_only
        costs = costs.where(category:) if category
        costs = costs.to_a
        { fixed_costs: costs.map { |cost| AdminMcp::Serializer.fixed_cost(cost) },
          monthly_total: AdminMcp::Serializer.money(costs.select(&:active?).sum(&:monthly_amount)),
          monthly_forecast_total: AdminMcp::Serializer.money(costs.select(&:active?).sum(&:monthly_forecast)) }
      end
  end
end
