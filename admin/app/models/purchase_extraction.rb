require "anthropic"

# Reads a purchase invoice (PDF or image) with Claude Haiku and returns its key fields as a hash.
# Runtime variable (Coolify): ANTHROPIC_API_KEY. The fields only prefill the purchase: a person checks them.
class PurchaseExtraction
  MODEL = "claude-haiku-5-5"

  class Error < StandardError; end

  NULLABLE_STRING = { anyOf: [ { type: "string" }, { type: "null" } ] }.freeze
  NULLABLE_NUMBER = { anyOf: [ { type: "number" }, { type: "null" } ] }.freeze

  SCHEMA = {
    type: "object",
    properties: {
      document_type: { type: "string", enum: %w[ invoice credit_note receipt other ] },
      supplier_name: NULLABLE_STRING,
      supplier_vat_number: NULLABLE_STRING,
      supplier_country: NULLABLE_STRING,
      invoice_number: NULLABLE_STRING,
      issue_date: NULLABLE_STRING,
      due_date: NULLABLE_STRING,
      currency: NULLABLE_STRING,
      net_amount: NULLABLE_NUMBER,
      vat_amount: NULLABLE_NUMBER,
      total_amount: NULLABLE_NUMBER,
      reverse_charge: { type: "boolean" },
      description: NULLABLE_STRING
    },
    required: %w[ document_type supplier_name supplier_vat_number supplier_country invoice_number issue_date due_date currency
                  net_amount vat_amount total_amount reverse_charge description ],
    additionalProperties: false
  }.freeze

  PROMPT = <<~PROMPT.freeze
    This document was sent to Super Génial (Marco & Vespucci SRL, a Belgian web agency) as a supplier invoice.
    Extract its fields. The supplier is the party that issued the document, never Super Génial or Marco & Vespucci.
    - document_type: "invoice", "credit_note", "receipt" (payment receipt without invoice details) or "other" (not an invoice).
    - supplier_country: ISO 3166-1 alpha-2 code of the issuing entity's address (e.g. "IE" for an Irish subsidiary).
    - supplier_vat_number: with its country prefix, as printed.
    - dates: ISO 8601 (YYYY-MM-DD).
    - currency: ISO 4217 code of the amounts.
    - net_amount, vat_amount, total_amount: document totals in that currency, as positive numbers, excluding VAT for net_amount.
    - reverse_charge: true when the document says VAT is reverse charged or due by the customer, or charges no VAT to a foreign business customer.
    - description: what was bought, in a few words, in French.
    Use null for any field the document does not show. Do not guess numbers.
  PROMPT

  def self.configured?(env = ENV) = env["ANTHROPIC_API_KEY"].present?

  def initialize(client: nil)
    @client = client || Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"), max_retries: 3)
  end

  def call(data, content_type:)
    message = @client.messages.create(
      model: MODEL,
      max_tokens: 2000,
      output_config: { effort: "low", format: { type: "json_schema", schema: SCHEMA } },
      messages: [ { role: "user", content: [ document_block(data, content_type), { type: "text", text: PROMPT } ] } ]
    )
    raise Error, "Claude n'a pas lu ce document (#{message.stop_reason})" unless message.stop_reason.to_s == "end_turn"
    text = message.content.select { |block| block.type.to_s == "text" }.map(&:text).join
    JSON.parse(text)
  rescue JSON::ParserError
    raise Error, "Réponse illisible de Claude"
  rescue Anthropic::Errors::Error => error
    raise Error, "Claude injoignable : #{error.message}"
  end

  private
    def document_block(data, content_type)
      encoded = Base64.strict_encode64(data)
      if content_type == "application/pdf"
        { type: "document", source: { type: "base64", media_type: content_type, data: encoded } }
      else
        { type: "image", source: { type: "base64", media_type: content_type, data: encoded } }
      end
    end
end
