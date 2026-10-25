# Sends an issued document through Recommand: over Peppol when the client is reachable there,
# by e-mail otherwise. Belgian companies must receive Peppol: e-mail is refused for them.
class InvoiceDelivery
  class Refused < StandardError; end

  def initialize(invoice, client: Recommand::Client.new)
    @invoice, @recommand = invoice, client
  end

  def deliver!
    raise Refused, "Émets le document avant de l'envoyer." unless @invoice.issued? && @invoice.admin?
    recipient = @invoice.client.peppol_id.presence || (@invoice.client.peppol_reachable? ? @invoice.client.suggested_peppol_id : nil)
    email = @invoice.client.invoicing_email
    raise Refused, "#{@invoice.client} est une entreprise belge : la facture doit partir par Peppol. Vérifie son identifiant Peppol." if recipient.nil? && @invoice.client.belgian_business?
    raise Refused, "Ni identifiant Peppol ni e-mail de facturation pour #{@invoice.client}." if recipient.nil? && email.blank?

    document = PeppolDocument.new(@invoice, pdf: InvoicePdf.new(@invoice).render)
    payload = { documentType: document.document_type, document: document.to_h, recipient: }
    payload[:email] = { when: recipient ? "on_peppol_failure" : "always", to: [ email ] } if email.present? && !@invoice.client.belgian_business?

    xml = @recommand.generate(payload.except(:email))["xml"]
    response = @recommand.send_document(payload)
    @invoice.update!(ubl_xml: xml, peppol_document_id: response["id"], sent_at: Time.current, send_error: nil,
                     peppol_status: response["sentOverPeppol"] ? "peppol" : (response["sentOverEmail"] ? "email" : "pending"))
    response
  rescue Recommand::Error => error
    @invoice.update!(send_error: error.message)
    raise
  end
end
