class AdminMcp::HourlyRates::AddHourlyRate < AdminMcp::Tool
  description "Set a new standard hourly rate from a date (past or future)."
  writes!
  input_schema(properties: { amount: { type: "number", minimum: 0 }, starts_on: { type: "string", format: "date" } },
               required: %w[ amount starts_on ])

  class << self
    private
      def perform(amount:, starts_on:)
        rate = HourlyRate.create!(amount:, starts_on: parse_date(starts_on, "starts_on"))
        { hourly_rate: AdminMcp::Serializer.hourly_rate(rate) }
      end
  end
end
