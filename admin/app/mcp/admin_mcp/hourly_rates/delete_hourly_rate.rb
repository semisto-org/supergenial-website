class AdminMcp::HourlyRates::DeleteHourlyRate < AdminMcp::Tool
  description "Delete one standard hourly rate (e.g. a change scheduled by mistake). At least one rate is kept."
  writes!(destructive: true, idempotent: true)
  input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])

  class << self
    private
      def perform(id:)
        rate = find(HourlyRate, id)
        raise ArgumentError, "At least one hourly rate must be kept." if HourlyRate.count == 1
        rate.destroy!
        { deleted: AdminMcp::Serializer.hourly_rate(rate) }
      end
  end
end
