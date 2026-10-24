require "test_helper"

class PurchaseImportsTest < ActiveSupport::TestCase
  class FakeRecommand
    attr_reader :read

    def initialize(documents) = (@documents, @read = documents, [])

    def inbox = @documents.map { |document| document.slice("id", "type") } + [ { "id" => "mlr_1", "type" => "messageLevelResponse" } ]

    def document(id) = @documents.find { |document| document["id"] == id }

    def mark_as_read(id) = @read << id
  end

  class FakeGmail
    attr_reader :labelled

    def initialize(messages) = (@messages, @labelled = messages, [])

    def message_ids(_query) = @messages.keys

    def message(id) = @messages.fetch(id)

    def attachment(_message_id, _attachment_id) = "%PDF-1.4 fictive"

    def label_id(_name) = "Label_1"

    def add_label(id, label) = @labelled << [ id, label ]
  end

  PEPPOL_DOCUMENT = {
    "id" => "doc_in_1", "type" => "invoice", "senderId" => "iso6523-actorid-upis::0208:0987654321", "xml" => "<Invoice/>",
    "parsed" => {
      "invoiceNumber" => "2026-0042", "issueDate" => "2026-10-15", "dueDate" => "2026-11-14", "currency" => "EUR",
      "seller" => { "name" => "Nouveau fournisseur fictif", "vatNumber" => "BE0987654321", "country" => "BE" },
      "totals" => { "taxExclusiveAmount" => "200.00", "payableAmount" => "242.00" },
      "vat" => { "totalVatAmount" => "42.00", "subtotals" => [ { "percentage" => "21.00" } ] },
      "attachments" => [ { "mimeCode" => "application/pdf", "filename" => "2026-0042.pdf", "embeddedDocument" => Base64.strict_encode64("%PDF-1.4") } ]
    }
  }.freeze

  test "Peppol documents become purchases with their UBL, PDF and supplier" do
    recommand = FakeRecommand.new([ PEPPOL_DOCUMENT ])
    purchase = assert_difference -> { Supplier.count } do
      PeppolPurchaseImport.new(client: recommand).run.sole
    end

    assert_equal [ "peppol", "2026-0042", 200, 42, "<Invoice/>" ], [ purchase.source, purchase.number, purchase.amount, purchase.vat_amount, purchase.ubl_xml ]
    assert_equal "0208:0987654321", purchase.supplier.peppol_id
    assert purchase.document.attached?
    assert_equal [ "doc_in_1" ], recommand.read, "other document types stay unread"

    assert_no_difference -> { PurchaseInvoice.count } do
      PeppolPurchaseImport.new(client: FakeRecommand.new([ PEPPOL_DOCUMENT ])).run
    end
  end

  test "PDF attachments of the mailbox become purchases to review" do
    message = {
      "id" => "msg_1",
      "payload" => {
        "headers" => [ { "name" => "From", "value" => "Facturation <billing@example.com>" }, { "name" => "Subject", "value" => "Votre facture" } ],
        "parts" => [
          { "partId" => "0", "mimeType" => "text/plain", "filename" => "", "body" => {} },
          { "partId" => "1", "mimeType" => "application/pdf", "filename" => "facture.pdf", "body" => { "attachmentId" => "att_1" } },
          { "partId" => "2", "mimeType" => "image/png", "filename" => "logo.png", "body" => { "attachmentId" => "att_2" } }
        ]
      }
    }
    gmail = FakeGmail.new("msg_1" => message)
    purchase = EmailPurchaseImport.new(client: gmail).run.sole

    assert_equal [ "email", "msg_1:1", "billing@example.com", "Votre facture" ], [ purchase.source, purchase.external_id, purchase.sender_email, purchase.email_subject ]
    assert purchase.document.attached?
    assert_equal [ [ "msg_1", "Label_1" ] ], gmail.labelled
    assert_no_difference -> { PurchaseInvoice.count } do
      EmailPurchaseImport.new(client: gmail).run
    end
  end
end
