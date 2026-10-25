class AdminMcp::Plans::DeletePlanPrice < AdminMcp::Tool
  description "Delete one dated price of a plan (e.g. a price change scheduled by mistake). A plan keeps at least one price."
  writes!(destructive: true, idempotent: true)
  input_schema(properties: { id: { type: "integer", description: "Id of the price (see list_plans)." } }, required: [ "id" ])

  class << self
    private
      def perform(id:)
        price = find(PlanPrice, id)
        raise ArgumentError, "A plan keeps at least one price." if price.plan.prices.size == 1
        price.destroy!
        { plan: AdminMcp::Serializer.plan(price.plan.reload) }
      end
  end
end
