class AdminMcp::Projects::SaveProject < AdminMcp::SaveTool
  description "Create a project for a client, or update it when id is given. " \
              "billing_mode: forfait (fixed_price), regie (by the hour) or pack (prepaid hours). " \
              "hourly_rate overrides the client's rate."
  model Project
  fields client_id: { type: "integer" },
         name: { type: "string" },
         kind: { type: "string", enum: Project::KINDS.keys },
         billing_mode: { type: "string", enum: Project::BILLING_MODES.keys },
         status: { type: "string", enum: Project::STATUSES.keys },
         fixed_price: { type: "number" },
         hourly_rate: { type: "number" },
         started_on: { type: "string", format: "date" },
         ended_on: { type: "string", format: "date" },
         notes: { type: "string" }
  required_on_create :client_id, :name

  class << self
    private
      def present(project) = { project: AdminMcp::Serializer.project(project, detail: true) }
  end
end
