# Append-only journal of every change: who (user and actor kind), what, when, and the before/after values.
class AuditEvent < ApplicationRecord
  skip_audit

  ACTIONS = { "create" => "Création", "update" => "Modification", "destroy" => "Suppression" }.freeze
  ACTOR_KINDS = { "user" => "Interface", "claude_mcp" => "Claude (MCP)", "system" => "Système" }.freeze

  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def self.record!(action:, auditable:, changeset: {})
    create!(action:, auditable_type: auditable.class.name, auditable_id: auditable.id, auditable_label: auditable.to_s.truncate(120),
            changeset:, user: Current.user, actor_kind: Current.actor_kind, request_id: Current.request_id)
  end

  def readonly? = persisted?

  def action_label = ACTIONS.fetch(action, action.humanize)

  def actor_label = [ user&.display_name, (ACTOR_KINDS[actor_kind] unless actor_kind == "user") ].compact.join(" · ").presence || "Système"

  def auditable_model_name = auditable_type.safe_constantize&.model_name&.human || auditable_type
end
