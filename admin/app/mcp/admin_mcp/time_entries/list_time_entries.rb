class AdminMcp::TimeEntries::ListTimeEntries < AdminMcp::Tool
  description "List time entries, most recent first. status a_facturer = unbilled, facture = billed, " \
              "au_pack = taken from a prepaid pack, offert = free."
  read_only!
  input_schema(properties: {
    client_id: { type: "integer" },
    project_id: { type: "integer" },
    pack_id: { type: "integer" },
    status: { type: "string", enum: TimeEntry::STATUSES.keys },
    from: { type: "string", format: "date" },
    to: { type: "string", format: "date" },
    limit: { type: "integer", minimum: 1, maximum: 500, description: "Defaults to 100." }
  })

  class << self
    private
      def perform(client_id: nil, project_id: nil, pack_id: nil, status: nil, from: nil, to: nil, limit: 100)
        entries = TimeEntry.recent.includes(:client, project: :client)
        entries = entries.where({ client_id:, project_id:, pack_id:, status: }.compact)
        entries = entries.where(performed_on: parse_date(from, "from")..) if from
        entries = entries.where(performed_on: ..parse_date(to, "to")) if to
        entries = entries.limit(limit).to_a
        { time_entries: entries.map { |entry| AdminMcp::Serializer.time_entry(entry) },
          total_hours: entries.sum(&:hours).to_f, total_amount: AdminMcp::Serializer.money(entries.sum(&:amount)) }
      end
  end
end
