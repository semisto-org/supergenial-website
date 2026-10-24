# Brings the documents received through Peppol (Recommand inbox) in as purchases to review,
# with their UBL (the legal original) and the PDF the supplier embedded, then marks them as read.
class PeppolPurchaseImport
  KINDS = { "invoice" => "invoice", "creditNote" => "credit_note" }.freeze

  def initialize(client: Recommand::Client.new)
    @client = client
  end

  # Returns the purchases created. Other document types (responses, reports) stay unread in Recommand.
  def run
    @client.inbox.filter_map do |summary|
      next unless KINDS.key?(summary["type"])
      purchase = import(@client.document(summary["id"]))
      @client.mark_as_read(summary["id"])
      purchase
    end
  end

  def import(document)
    purchase = PurchaseInvoice.find_or_initialize_by(source: "peppol", external_id: document["id"])
    return purchase if purchase.persisted?

    parsed = document["parsed"] || {}
    seller = parsed["seller"] || {}
    net = parsed.dig("totals", "taxExclusiveAmount").to_d.abs
    purchase.assign_attributes(
      kind: KINDS.fetch(document["type"], "invoice"),
      number: parsed["invoiceNumber"] || parsed["creditNoteNumber"],
      issued_on: parsed["issueDate"], due_on: parsed["dueDate"],
      currency: parsed["currency"].presence || "EUR", original_amount: net,
      vat_amount: parsed.dig("vat", "totalVatAmount").to_d.abs,
      vat_rate: Array(parsed.dig("vat", "subtotals")).map { |subtotal| subtotal["percentage"].to_d }.max || 21,
      seller_name: seller["name"], seller_vat_number: seller["vatNumber"], seller_country: seller["country"],
      ubl_xml: document["xml"]
    )
    purchase.amount = net unless purchase.foreign_currency?
    purchase.supplier = purchase.match_supplier.supplier || create_supplier(seller, document["senderId"])
    purchase.expense_category ||= purchase.supplier.expense_category
    attach_pdf(purchase, parsed["attachments"])
    purchase.save!
    purchase
  end

  private
    def create_supplier(seller, sender_id)
      Supplier.create!(name: seller["name"].presence || "Fournisseur Peppol", vat_number: seller["vatNumber"],
                       billing_country: seller["country"].presence || "BE", peppol_id: sender_id.to_s.delete_prefix("iso6523-actorid-upis::").presence)
    end

    def attach_pdf(purchase, attachments)
      pdf = Array(attachments).find { |attachment| attachment["mimeCode"] == "application/pdf" && attachment["embeddedDocument"].present? }
      return unless pdf
      purchase.document.attach(io: StringIO.new(Base64.decode64(pdf["embeddedDocument"])), filename: pdf["filename"].presence || "#{purchase.number}.pdf",
                               content_type: "application/pdf")
    end
end
