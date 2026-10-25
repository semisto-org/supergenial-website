class AdminMcp::Contacts::SaveContact < AdminMcp::SaveTool
  description "Create a contact for a client, or update it when id is given. " \
              "Marking a contact as primary removes the flag from the client's other contacts."
  model Contact
  fields client_id: { type: "integer" },
         first_name: { type: "string" },
         last_name: { type: "string" },
         role: { type: "string" },
         email: { type: "string" },
         phone: { type: "string" },
         primary: { type: "boolean" }
  required_on_create :client_id, :first_name

  class << self
    private
      def present(contact) = { contact: AdminMcp::Serializer.contact(contact) }
  end
end
