class AdminMcp::TimeEntries::BillTimeEntries < AdminMcp::Tool
  description "Create a draft invoice billing unbilled (a_facturer) time entries of a single client, one line per entry, " \
              "and mark them as billed. Review the draft with get_invoice, then issue it with issue_invoice."
  writes!
  input_schema(properties: { ids: { type: "array", items: { type: "integer" }, minItems: 1 } }, required: [ "ids" ])

  class << self
    private
      def perform(ids:)
        entries = TimeEntry.a_facturer.where(id: ids).includes(:client, :project)
        missing = ids - entries.map(&:id)
        raise ArgumentError, "Not unbilled or not found: #{missing.join(", ")}" if missing.any?

        invoice = TimeEntry.bill!(entries)
        { invoice: AdminMcp::Serializer.invoice(invoice, detail: true), billed_time_entry_ids: entries.map(&:id) }
      end
  end
end
