class AdminMcp::Clients::MergeClients < AdminMcp::Tool
  description "Merge a duplicate client into the client to keep: contacts, projects, time entries, contracts, packs, " \
              "invoices (issued ones included) and comments move to the kept client, its blank details are filled from " \
              "the duplicate, then the duplicate is deleted. Irreversible: show both clients to the user and ask for confirmation first."
  writes!(destructive: true)
  input_schema(
    properties: {
      kept_id: { type: "integer", description: "The client that remains." },
      duplicate_id: { type: "integer", description: "The client merged into kept_id, then deleted." }
    },
    required: %w[ kept_id duplicate_id ]
  )

  class << self
    private
      def perform(kept_id:, duplicate_id:)
        raise ArgumentError, "kept_id and duplicate_id must be two different clients" if kept_id == duplicate_id

        kept = find(Client, kept_id)
        duplicate = find(Client, duplicate_id)
        merge = ClientMerge.new(kept:, duplicate:).merge!
        { merged: { deleted_client: { id: duplicate.id, name: duplicate.name }, moved: merge.moved },
          client: AdminMcp::Serializer.client(kept.reload, detail: true) }
      end
  end
end
