class AdminMcp::Plans::AddPlanPrice < AdminMcp::Tool
  description "Schedule a plan price from a date (past or future). Contracts on this plan without a negotiated " \
              "amount follow it from that date."
  writes!
  input_schema(properties: {
    plan_id: { type: "integer" },
    amount: { type: "number", minimum: 0 },
    starts_on: { type: "string", format: "date" }
  }, required: %w[ plan_id amount starts_on ])

  class << self
    private
      def perform(plan_id:, amount:, starts_on:)
        plan = find(Plan, plan_id)
        plan.prices.create!(amount:, starts_on: parse_date(starts_on, "starts_on"))
        { plan: AdminMcp::Serializer.plan(plan.reload) }
      end
  end
end
