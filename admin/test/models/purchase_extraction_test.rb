require "test_helper"

class PurchaseExtractionTest < ActiveSupport::TestCase
  class FakeClient
    Block = Struct.new(:type, :text)
    Message = Struct.new(:stop_reason, :content)
    attr_reader :params

    def initialize(text, stop_reason: :end_turn) = (@text, @stop_reason = text, stop_reason)

    def messages = self

    def create(**params)
      @params = params
      Message.new(@stop_reason, [ Block.new(:text, @text) ])
    end
  end

  test "sends the PDF to Claude Haiku and parses the structured answer" do
    client = FakeClient.new({ document_type: "invoice", invoice_number: "F-1", net_amount: 10 }.to_json)
    data = PurchaseExtraction.new(client:).call("%PDF-1.4", content_type: "application/pdf")

    assert_equal "F-1", data["invoice_number"]
    assert_equal "claude-haiku-5-5", client.params[:model]
    document, text = client.params[:messages].first[:content]
    assert_equal [ "document", "application/pdf" ], [ document[:type], document[:source][:media_type] ]
    assert_equal "text", text[:type]
    assert_equal "json_schema", client.params.dig(:output_config, :format, :type)
  end

  test "a refusal or a cut answer is an error" do
    assert_raises(PurchaseExtraction::Error) { PurchaseExtraction.new(client: FakeClient.new("", stop_reason: :refusal)).call("x", content_type: "image/png") }
    assert_raises(PurchaseExtraction::Error) { PurchaseExtraction.new(client: FakeClient.new("{")).call("x", content_type: "image/png") }
  end

  test "the job prefills the purchase" do
    purchase = PurchaseInvoice.new(source: "email", extraction_status: "pending")
    purchase.document.attach(io: file_fixture("invoice.pdf").open, filename: "invoice.pdf")
    purchase.save!
    client = FakeClient.new({ document_type: "credit_note", supplier_vat_number: "BE 0123.456.789", invoice_number: "NC-3",
                              issue_date: "2026-10-12", currency: "EUR", net_amount: -40, vat_amount: -8.4, reverse_charge: false }.to_json)

    PurchaseExtractionJob.perform_now(purchase, extraction: PurchaseExtraction.new(client:))
    purchase.reload
    assert_equal [ "done", "credit_note", suppliers(:belgian) ], [ purchase.extraction_status, purchase.kind, purchase.supplier ]
    assert_equal [ 40, 8.4 ], [ purchase.amount, purchase.vat_amount ]
    assert_equal "domestic", purchase.vat_regime
  end
end
