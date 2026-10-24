class AdminMcp::Plans::ListPlans < AdminMcp::Tool
  description "List subscription plans (Essentiel, Évolution…) with their dated price history, current price, " \
              "number of active contracts and yearly revenue."
  read_only!
  input_schema(properties: { active_only: { type: "boolean" } })

  class << self
    private
      def perform(active_only: false)
        plans = Plan.ordered.includes(:prices, contracts: { plan: :prices })
        plans = plans.active if active_only
        { plans: plans.map { |plan| AdminMcp::Serializer.plan(plan) } }
      end
  end
end
