class AdminMcp::Clients::SearchClients < AdminMcp::Tool
  description "Find clients by name, VAT number or contact (name, email, phone). Without a query, lists every client."
  read_only!
  input_schema(properties: {
    query: { type: "string" },
    status: { type: "string", enum: Client::STATUSES.keys },
    kind: { type: "string", enum: Client::KINDS.keys }
  })

  class << self
    private
      def perform(query: nil, status: nil, kind: nil)
        clients = Client.alphabetical.includes(:contacts)
        clients = clients.where(status:) if status
        clients = clients.where(kind:) if kind
        if query.present?
          pattern = "%#{Client.sanitize_sql_like(query)}%"
          clients = clients.left_joins(:contacts).distinct.where(
            "clients.name LIKE :pattern OR clients.vat_number LIKE :pattern OR contacts.first_name LIKE :pattern OR " \
            "contacts.last_name LIKE :pattern OR contacts.email LIKE :pattern OR contacts.phone LIKE :pattern", pattern:
          )
        end
        { clients: clients.map { |client| AdminMcp::Serializer.client(client) } }
      end
  end
end
