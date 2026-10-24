class AdminMcp::Contracts::SaveContract < AdminMcp::SaveTool
  description "Create a recurring contract, or update it when id is given. A contract has one or more kinds. " \
              "Linked to a plan (plan_id) with no amount, it follows the plan's dated prices and period; " \
              "an amount is a negotiated price. Without a plan, amount is required. cost is what it costs Super Génial " \
              "(e.g. a linked fixed cost), used for the margin."
  model Contract
  fields client_id: { type: "integer" },
         label: { type: "string" },
         kinds: { type: "array", items: { type: "string", enum: Contract::KINDS.keys }, minItems: 1 },
         plan_id: { type: "integer" },
         project_id: { type: "integer" },
         fixed_cost_id: { type: "integer" },
         amount: { type: "number", minimum: 0 },
         cost: { type: "number", minimum: 0 },
         period: { type: "string", enum: Periodic::PERIODS.keys },
         status: { type: "string", enum: Contract::STATUSES.keys },
         starts_on: { type: "string", format: "date" },
         next_billing_on: { type: "string", format: "date" },
         registrar: { type: "string", description: "Domain registrar, for domain name contracts." },
         notes: { type: "string" }
  required_on_create :client_id, :label, :kinds

  class << self
    private
      def present(contract) = { contract: AdminMcp::Serializer.contract(contract, detail: true) }
  end
end
