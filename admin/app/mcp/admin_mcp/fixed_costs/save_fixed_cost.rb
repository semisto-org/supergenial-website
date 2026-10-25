class AdminMcp::FixedCosts::SaveFixedCost < AdminMcp::SaveTool
  description "Create a fixed cost, or update it when id is given. forecast_amount is what it will cost after " \
              "planned changes (null = unchanged, 0 = cancelled); action describes the planned change."
  model FixedCost
  fields name: { type: "string" },
         category: { type: "string", enum: FixedCost::CATEGORIES.keys },
         supplier_id: { type: "integer" },
         amount: { type: "number", minimum: 0 },
         period: { type: "string", enum: Periodic::PERIODS.keys },
         forecast_amount: { type: "number", minimum: 0 },
         renews_on: { type: "string", format: "date" },
         action: { type: "string" },
         billing_url: { type: "string" },
         active: { type: "boolean" },
         notes: { type: "string" }
  required_on_create :name, :amount

  class << self
    private
      def present(cost) = { fixed_cost: AdminMcp::Serializer.fixed_cost(cost) }
  end
end
