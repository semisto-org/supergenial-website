class AdminMcp::Contracts::GetContract < AdminMcp::Tool
  description "Full contract record: price (plan price or negotiated amount), margin, next plan price change, revenue over the next 12 months."
  read_only!
  input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])

  class << self
    private
      def perform(id:) = { contract: AdminMcp::Serializer.contract(find(Contract, id), detail: true) }
  end
end
