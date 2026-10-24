require "test_helper"

class InvoiceDeliveryTest < ActiveSupport::TestCase
  class FakeRecommand
    attr_reader :sent

    def initialize(response) = @response = response

    def generate(_payload) = { "xml" => "<Invoice/>" }

    def send_document(payload)
      @sent = payload
      @response
    end
  end

  def issued(client)
    Invoice.create!(client:, label: "Site", issued_on: Date.current, vat_regime: VatRegime.suggest(client),
                    lines_attributes: [ { description: "Développement", quantity: 1, unit_price: 500, vat_rate: 21 } ]).tap(&:issue!)
  end

  test "belgian companies receive their invoice over Peppol" do
    clients(:dici).update!(peppol_id: "0208:0888888888")
    recommand = FakeRecommand.new("success" => true, "id" => "doc_1", "sentOverPeppol" => true)
    invoice = issued(clients(:dici))
    InvoiceDelivery.new(invoice, client: recommand).deliver!

    assert_equal "0208:0888888888", recommand.sent[:recipient]
    assert_nil recommand.sent[:email], "no e-mail fallback for a Belgian company"
    assert_equal [ "peppol", "doc_1", "<Invoice/>" ], [ invoice.peppol_status, invoice.peppol_document_id, invoice.ubl_xml ]
  end

  test "e-mail is refused for a belgian company without Peppol" do
    clients(:dici).update!(billing_email: "compta@example.com")
    invoice = issued(clients(:dici))
    assert_raises(InvoiceDelivery::Refused) { InvoiceDelivery.new(invoice, client: FakeRecommand.new({})).deliver! }
  end

  test "foreign clients without Peppol get an e-mail" do
    recommand = FakeRecommand.new("success" => true, "id" => "doc_2", "sentOverPeppol" => false, "sentOverEmail" => true)
    invoice = issued(clients(:lux))
    InvoiceDelivery.new(invoice, client: recommand).deliver!

    assert_nil recommand.sent[:recipient]
    assert_equal({ when: "always", to: [ "compta@example.com" ] }, recommand.sent[:email])
    assert_equal "email", invoice.peppol_status
  end

  test "drafts are not sent" do
    invoice = Invoice.create!(client: clients(:dici), label: "x", issued_on: Date.current, lines_attributes: [ { description: "x", unit_price: 1 } ])
    assert_raises(InvoiceDelivery::Refused) { InvoiceDelivery.new(invoice, client: FakeRecommand.new({})).deliver! }
  end
end
