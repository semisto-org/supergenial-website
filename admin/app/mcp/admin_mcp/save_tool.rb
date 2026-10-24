# Creates a record, or updates it when `id` is given. Subclasses declare the model and its fields:
#
#   model Client
#   fields name: { type: "string" }, status: { type: "string", enum: Client::STATUSES.keys }
#   required_on_create :name
#
# Every field except `id` is optional and nullable, so a single call can clear a value.
class AdminMcp::SaveTool < AdminMcp::Tool
  class << self
    def model(value = nil)
      value ? @model = value : @model
    end

    def fields(definitions = nil)
      return @fields || {} unless definitions
      @fields = definitions
      writes!(idempotent: true)
      input_schema(properties: { id: { type: "integer", description: "Id of the #{model.model_name.human.downcase} to update; omit to create one." } }
                     .merge(definitions.transform_values { |definition| nullable(definition) }))
    end

    def required_on_create(*names)
      names.empty? ? (@required_on_create || []) : @required_on_create = names
    end

    private
      def perform(id: nil, **attributes)
        record = id ? find(model, id) : model.new
        missing = required_on_create.select { |name| attributes[name].blank? } if record.new_record?
        raise ArgumentError, "Missing required fields to create: #{missing.join(", ")}" if missing.present?

        record.update!(normalize(attributes.slice(*fields.keys)))
        present(record.reload)
      end

      def normalize(attributes) = attributes

      def present(record) = raise(NotImplementedError)

      def nullable(definition)
        type = Array(definition[:type]) | [ "null" ]
        definition = definition.merge(type:)
        definition[:enum] ? definition.merge(enum: definition[:enum] + [ nil ]) : definition
      end
  end
end
