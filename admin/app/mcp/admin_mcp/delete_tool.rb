# Deletes a record by id. Subclasses declare the model and can explain side effects in their description.
class AdminMcp::DeleteTool < AdminMcp::Tool
  class << self
    def model(value = nil)
      return @model unless value
      @model = value
      writes!(destructive: true, idempotent: true)
      input_schema(properties: { id: { type: "integer" } }, required: [ "id" ])
    end

    private
      def perform(id:)
        record = find(model, id)
        record.destroy!
        { deleted: { type: model.name, id: record.id, name: record.to_s } }
      end
  end
end
