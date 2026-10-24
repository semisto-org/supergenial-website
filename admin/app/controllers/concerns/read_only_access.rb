# Read-only users (the accountant) can browse everything but not change it.
# A controller lets them write with `allow_read_only_writes` (comments, closing a VAT period…).
module ReadOnlyAccess
  extend ActiveSupport::Concern

  WRITE_FORM_ACTIONS = %w[ new edit ].freeze

  included do
    before_action :forbid_writes_for_read_only_users
    helper_method :can_write?
  end

  class_methods do
    def allow_read_only_writes(**options)
      skip_before_action :forbid_writes_for_read_only_users, **options
    end

    def require_admin(**options)
      before_action(**options) { forbid_write unless Current.user&.admin? }
    end
  end

  private
    def can_write? = Current.user.nil? || Current.user.can_write?

    def forbid_writes_for_read_only_users
      return if can_write?
      forbid_write unless request.get? || request.head?
      forbid_write if action_name.in?(WRITE_FORM_ACTIONS)
    end

    def forbid_write
      return if performed?
      redirect_back_or_to root_path, alert: "Ton accès est en lecture seule : tu peux commenter, pas modifier."
    end
end
