class AdminMcp::Plans::SavePlan < AdminMcp::SaveTool
  description "Create a subscription plan with its first price, or update it when id is given. " \
              "Prices are never edited in place: use add_plan_price to schedule a new price from a date."
  model Plan
  fields name: { type: "string" },
         description: { type: "string" },
         period: { type: "string", enum: Periodic::PERIODS.keys },
         position: { type: "integer" },
         active: { type: "boolean" },
         first_price: { type: "number", minimum: 0, description: "Required to create a plan." },
         first_price_starts_on: { type: "string", format: "date", description: "Defaults to today." }
  required_on_create :name, :first_price

  class << self
    private
      def normalize(attributes)
        price, starts_on = attributes.extract!(:first_price, :first_price_starts_on).values_at(:first_price, :first_price_starts_on)
        price ? attributes.merge(prices_attributes: [ { amount: price, starts_on: starts_on || Date.current } ]) : attributes
      end

      def present(plan) = { plan: AdminMcp::Serializer.plan(plan) }
  end
end
