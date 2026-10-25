class AdminMcp::Packs::SavePack < AdminMcp::SaveTool
  description "Create a prepaid hour pack for a client, or update it when id is given. " \
              "invoice_id links the invoice that sold the pack."
  model Pack
  fields client_id: { type: "integer" },
         label: { type: "string" },
         hours: { type: "number", exclusiveMinimum: 0 },
         hourly_rate: { type: "number" },
         purchased_on: { type: "string", format: "date" },
         invoice_id: { type: "integer" }
  required_on_create :client_id, :label, :hours

  class << self
    private
      def present(pack) = { pack: AdminMcp::Serializer.pack(pack) }
  end
end
