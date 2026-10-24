class AdminMcp::Projects::ListProjects < AdminMcp::Tool
  description "List projects, optionally filtered by client, status or name. ongoing_only keeps quotes, " \
              "waiting, in-progress and maintenance projects."
  read_only!
  input_schema(properties: {
    client_id: { type: "integer" },
    status: { type: "string", enum: Project::STATUSES.keys },
    ongoing_only: { type: "boolean" },
    query: { type: "string" }
  })

  class << self
    private
      def perform(client_id: nil, status: nil, ongoing_only: false, query: nil)
        projects = Project.includes(:client).order(started_on: :desc, id: :desc)
        projects = projects.where(client_id:) if client_id
        projects = projects.where(status:) if status
        projects = projects.ongoing if ongoing_only
        projects = projects.where("projects.name LIKE ?", "%#{Project.sanitize_sql_like(query)}%") if query.present?
        { projects: projects.map { |project| AdminMcp::Serializer.project(project) } }
      end
  end
end
