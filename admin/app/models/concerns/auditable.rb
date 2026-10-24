# Writes an AuditEvent for every create, update and destroy, inside the same transaction.
# Included in ApplicationRecord; a model opts out with `skip_audit`.
module Auditable
  extend ActiveSupport::Concern

  IGNORED_ATTRIBUTES = %w[ id created_at updated_at ].freeze
  FILTERED_ATTRIBUTES = %w[ password_digest otp_secret otp_last_used_at ].freeze

  included do
    class_attribute :audited, default: true

    after_create { audit("create", audit_attributes.transform_values { |value| [ nil, value ] }) }
    after_update { audit("update", audit_changes) if audit_changes.any? }
    after_destroy { audit("destroy", audit_attributes.transform_values { |value| [ value, nil ] }) }
  end

  class_methods do
    def skip_audit = self.audited = false
  end

  private
    def audit(action, changeset)
      AuditEvent.record!(action:, auditable: self, changeset:) if audited
    end

    def audit_attributes
      attributes.except(*IGNORED_ATTRIBUTES).compact.to_h { |name, value| [ name, audit_value(name, value) ] }
    end

    def audit_changes
      saved_changes.except(*IGNORED_ATTRIBUTES).to_h do |name, (before, after)|
        [ name, [ audit_value(name, before), audit_value(name, after) ] ]
      end
    end

    def audit_value(name, value)
      return "[filtré]" if FILTERED_ATTRIBUTES.include?(name) && !value.nil?
      value.is_a?(BigDecimal) ? value.to_s("F") : value
    end
end
