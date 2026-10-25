class AdminMcp::Packs::ListPacks < AdminMcp::Tool
  description "List prepaid hour packs with used and remaining hours."
  read_only!
  input_schema(properties: { client_id: { type: "integer" }, with_remaining_hours_only: { type: "boolean" } })

  class << self
    private
      def perform(client_id: nil, with_remaining_hours_only: false)
        packs = Pack.includes(:client, :time_entries).order(purchased_on: :desc)
        packs = packs.where(client_id:) if client_id
        packs = packs.reject(&:exhausted?) if with_remaining_hours_only
        { packs: packs.map { |pack| AdminMcp::Serializer.pack(pack).merge(client_name: pack.client.name) } }
      end
  end
end
