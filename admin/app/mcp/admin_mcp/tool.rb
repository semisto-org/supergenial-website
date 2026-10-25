# Base class of every admin tool: permissions, audit actor, error handling and JSON output.
# Subclasses implement `perform(**arguments)` and return a Hash.
class AdminMcp::Tool < MCP::Tool
  class Forbidden < StandardError; end

  class << self
    def read_only!
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)
    end

    def writes!(destructive: false, idempotent: false)
      annotations(read_only_hint: false, destructive_hint: destructive, idempotent_hint: idempotent, open_world_hint: false)
    end

    def write? = !annotations_value&.read_only_hint

    def can_write?(user) = user&.can_write?

    def call(server_context:, **arguments)
      user = server_context[:user]
      raise Forbidden, "This account has read-only access." if write? && !can_write?(user)

      result = as_actor(user) { perform(**arguments) }
      MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(result) } ], structured_content: result)
    rescue Forbidden, ArgumentError, ActiveRecord::RecordNotFound => error
      error_response(error.message)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => error
      error_response("#{error.record.class.model_name.human} : #{error.record.errors.full_messages.to_sentence.presence || error.message}")
    end

    private
      def perform(**)
        raise NotImplementedError
      end

      # Changes are attributed to the signed-in user, acting through Claude.
      def as_actor(user, &) = Current.set({ user:, actor_kind: "claude_mcp" }, &)

      def error_response(message)
        MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
      end

      def find(model, id) = model.find(id)

      # Accepts "YYYY-MM-DD" strings coming from JSON.
      def parse_date(value, name = "date")
        value.presence && Date.iso8601(value.to_s)
      rescue Date::Error
        raise ArgumentError, "#{name} must be a date (YYYY-MM-DD)"
      end
  end
end
