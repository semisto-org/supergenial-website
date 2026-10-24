# Turns the PDF attachments of the purchases mailbox into purchases to review, then labels the messages
# so that they are not imported twice. Claude reads each PDF in the background to prefill the purchase.
class EmailPurchaseImport
  LABEL = "admin-importee"
  QUERY = "has:attachment filename:pdf -label:#{LABEL} newer_than:180d".freeze

  def initialize(client: Gmail::Client.new)
    @client = client
  end

  # Returns the purchases created.
  def run
    message_ids = @client.message_ids(QUERY)
    return [] if message_ids.empty?

    label = @client.label_id(LABEL)
    message_ids.flat_map do |id|
      purchases = import(@client.message(id))
      @client.add_label(id, label)
      purchases
    end
  end

  def import(message)
    headers = Array(message.dig("payload", "headers")).to_h { |header| [ header["name"].downcase, header["value"] ] }
    pdf_parts(message["payload"]).filter_map do |part|
      external_id = "#{message['id']}:#{part['partId']}"
      next if PurchaseInvoice.exists?(source: "email", external_id:)

      purchase = PurchaseInvoice.new(source: "email", external_id:, sender_email: sender(headers["from"]), email_subject: headers["subject"].to_s.truncate(250),
                                     extraction_status: ("pending" if PurchaseExtraction.configured?))
      purchase.document.attach(io: StringIO.new(@client.attachment(message["id"], part.dig("body", "attachmentId"))),
                               filename: part["filename"], content_type: "application/pdf")
      purchase.save!
      PurchaseExtractionJob.perform_later(purchase) if purchase.extraction_pending?
      purchase
    end
  end

  private
    def pdf_parts(part)
      return [] unless part
      own = part["filename"].to_s.downcase.end_with?(".pdf") && part.dig("body", "attachmentId") ? [ part ] : []
      own + Array(part["parts"]).flat_map { |child| pdf_parts(child) }
    end

    def sender(from)
      Mail::Address.new(from.to_s).address
    rescue Mail::Field::ParseError
      from
    end
end
