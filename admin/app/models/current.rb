class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :actor_kind, :request_id, :hourly_rates

  # The user comes from the browser session, or is set directly (MCP server, jobs, rake tasks).
  def user = super || session&.user

  # "user" for people in the browser, "claude_mcp" for the MCP server, "system" for jobs and imports.
  def actor_kind = super || "user"
end
