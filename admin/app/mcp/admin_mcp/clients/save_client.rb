class AdminMcp::Clients::SaveClient < AdminMcp::SaveTool
  description "Create a client, or update it when id is given. hourly_rate overrides the standard hourly rate " \
              "(see list_hourly_rates) for its time entries."
  model Client
  fields name: { type: "string" },
         kind: { type: "string", enum: Client::KINDS.keys },
         status: { type: "string", enum: Client::STATUSES.keys },
         vat_number: { type: "string" },
         street: { type: "string" },
         postal_code: { type: "string" },
         city: { type: "string" },
         country: { type: "string", description: "ISO 3166-1 alpha-2 code, e.g. BE." },
         billing_email: { type: "string", description: "Where invoices go when the client is not on Peppol." },
         peppol_id: { type: "string", description: "Peppol participant id, e.g. 0208:0123456789." },
         hourly_rate: { type: "number" },
         notes: { type: "string" }
  required_on_create :name

  class << self
    private
      def present(client) = { client: AdminMcp::Serializer.client(client, detail: true) }
  end
end
