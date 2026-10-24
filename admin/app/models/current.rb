class Current < ActiveSupport::CurrentAttributes
  attribute :session, :hourly_rates
  delegate :user, to: :session, allow_nil: true
end
