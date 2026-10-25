class AdminMcp::Contracts::ListContracts < AdminMcp::Tool
  description "List recurring contracts by next billing date. Domain names are contracts of kind nom_de_domaine " \
              "(with their registrar). By default only active contracts are listed."
  read_only!
  input_schema(properties: {
    client_id: { type: "integer" },
    kind: { type: "string", enum: Contract::KINDS.keys },
    status: { type: "string", enum: Contract::STATUSES.keys + [ "all" ], description: "Defaults to actif." },
    plan_id: { type: "integer" },
    due_within_days: { type: "integer", minimum: 0, description: "Only active contracts to bill within this many days." }
  })

  class << self
    private
      def perform(client_id: nil, kind: nil, status: "actif", plan_id: nil, due_within_days: nil)
        contracts = Contract.includes(:client, plan: :prices).by_due_date
        contracts = contracts.where(client_id:) if client_id
        contracts = contracts.where(plan_id:) if plan_id
        contracts = contracts.of_kind(kind) if kind
        contracts = contracts.where(status:) unless status == "all"
        contracts = contracts.due_by(Date.current + due_within_days.days) if due_within_days
        contracts = contracts.to_a
        { contracts: contracts.map { |contract| AdminMcp::Serializer.contract(contract) },
          yearly_total: AdminMcp::Serializer.money(contracts.select(&:actif?).sum(&:yearly_amount)) }
      end
  end
end
