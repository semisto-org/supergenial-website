class AdminMcp::TimeEntries::SaveTimeEntry < AdminMcp::SaveTool
  description "Log time for a client (optionally on a project or a prepaid pack), or update an entry when id is given. " \
              "An entry on a pack automatically gets the au_pack status; otherwise it starts as a_facturer."
  model TimeEntry
  fields client_id: { type: "integer" },
         project_id: { type: "integer" },
         pack_id: { type: "integer" },
         performed_on: { type: "string", format: "date" },
         hours: { type: "number", exclusiveMinimum: 0 },
         description: { type: "string" },
         km: { type: "integer" },
         location: { type: "string" },
         status: { type: "string", enum: TimeEntry::STATUSES.keys }
  required_on_create :client_id, :performed_on, :hours

  class << self
    private
      def present(entry) = { time_entry: AdminMcp::Serializer.time_entry(entry) }
  end
end
