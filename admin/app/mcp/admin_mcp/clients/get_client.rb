class AdminMcp::Clients::GetClient < AdminMcp::Tool
  description "Full client record: contacts, projects, contracts, packs, recent invoices and unbilled hours."
  read_only!
  input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])

  class << self
    private
      def perform(id:) = { client: AdminMcp::Serializer.client(find(Client, id), detail: true) }
  end
end
