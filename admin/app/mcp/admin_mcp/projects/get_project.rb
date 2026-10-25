class AdminMcp::Projects::GetProject < AdminMcp::Tool
  description "Full project record: hours spent, amount invoiced, recent time entries, contracts and invoices."
  read_only!
  input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])

  class << self
    private
      def perform(id:) = { project: AdminMcp::Serializer.project(find(Project, id), detail: true) }
  end
end
