class AdminMcp::HourlyRates::ListHourlyRates < AdminMcp::Tool
  description "List the standard hourly rate history. A time entry uses the rate in force on its date, " \
              "unless its project or client has its own hourly_rate."
  read_only!

  class << self
    private
      def perform
        next_change = HourlyRate.next_change
        { current_rate: AdminMcp::Serializer.money(HourlyRate.on(Date.current)),
          next_change: next_change && AdminMcp::Serializer.hourly_rate(next_change),
          rates: HourlyRate.chronological.map { |rate| AdminMcp::Serializer.hourly_rate(rate) } }
      end
  end
end
