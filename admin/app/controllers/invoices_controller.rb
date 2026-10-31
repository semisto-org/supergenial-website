class InvoicesController < ApplicationController
  EXTRA_BLANK_LINES = 1

  before_action :set_invoice, only: %i[ show edit update destroy issue deliver credit_note pdf ubl ]

  def index
    @year = (params[:year] || Date.current.year).to_i
    @invoices = Invoice.in_year(@year).includes(:client).recent
    @drafts = Invoice.draft.includes(:client).recent
  end

  def show
  end

  # A new sales document from the admin; ?source=okioki references an older OkiOki document instead.
  def new
    source = params[:source] == "okioki" ? "okioki" : "admin"
    @invoice = Invoice.new(client_id: preselected_client_id, issued_on: Date.current, source:, status: source == "admin" ? "draft" : "issued")
    @invoice.vat_regime = VatRegime.suggest(@invoice.client) if @invoice.client
    add_blank_lines
  end

  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.status = @invoice.admin? ? "draft" : "issued"
    @invoice.kind = "invoice" if @invoice.okioki?
    if @invoice.save
      redirect_to @invoice, notice: @invoice.draft? ? "Brouillon enregistré : vérifie-le, puis émets-le." : "Facture enregistrée."
    else
      add_blank_lines
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to @invoice, alert: "Une facture émise ne se modifie plus : crée une note de crédit." and return if @invoice.locked?
    add_blank_lines
  end

  def update
    if @invoice.update(@invoice.locked? ? params.expect(invoice: %i[ paid_on notes ]) : invoice_params)
      redirect_to @invoice, notice: "Facture mise à jour."
    else
      add_blank_lines
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.destroy
      redirect_to invoices_path, notice: "#{@invoice.kind_label} supprimée.", status: :see_other
    else
      redirect_to @invoice, alert: @invoice.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def issue
    @invoice.issue!(on: params[:issued_on].presence&.to_date || Date.current)
    redirect_to @invoice, notice: "#{@invoice.kind_label} #{@invoice.number} émise."
  rescue ActiveRecord::RecordInvalid
    redirect_to @invoice, alert: @invoice.errors.full_messages.to_sentence
  end

  def deliver
    response = InvoiceDelivery.new(@invoice).deliver!
    channel = response["sentOverPeppol"] ? "par Peppol" : "par e-mail (#{Array(response['emailRecipients']).join(', ')})"
    redirect_to @invoice, notice: "#{@invoice.kind_label} #{@invoice.number} envoyée #{channel}."
  rescue InvoiceDelivery::Refused, Recommand::Error, KeyError => error
    message = error.is_a?(KeyError) ? "Recommand n'est pas configuré (variables RECOMMAND_* dans Coolify)." : error.message
    redirect_to @invoice, alert: message
  end

  def credit_note
    credit_note = @invoice.build_credit_note
    credit_note.save!
    redirect_to edit_invoice_path(credit_note), notice: "Note de crédit en brouillon : ajuste les lignes à créditer, puis émets-la."
  end

  def pdf
    if !@invoice.admin? && @invoice.document.attached?
      return send_data @invoice.document.download, filename: @invoice.document.filename.to_s, type: "application/pdf", disposition: params[:download] ? "attachment" : "inline"
    end
    document = InvoicePdf.new(@invoice)
    send_data document.render, filename: document.filename, type: "application/pdf", disposition: params[:download] ? "attachment" : "inline"
  end

  def ubl
    return redirect_to(@invoice, alert: "Pas encore d'UBL : il est produit à l'envoi.") if @invoice.ubl_xml.blank?
    send_data @invoice.ubl_xml, filename: "#{@invoice.number}.xml", type: "application/xml"
  end

  private
    def set_invoice
      @invoice = Invoice.find(params[:id])
    end

    def add_blank_lines
      return unless @invoice.admin?
      return if @invoice.lines.any?(&:new_record?)
      EXTRA_BLANK_LINES.times { @invoice.lines.build(vat_rate: 21, quantity: 1, position: @invoice.lines.size) }
    end

    def invoice_params
      params.expect(invoice: [ :client_id, :project_id, :number, :label, :issued_on, :amount, :paid_on, :notes, :source, :vat_regime,
                               lines_attributes: [ [ :id, :position, :description, :quantity, :unit, :unit_price, :vat_rate, :period_start, :period_end, :_destroy ] ] ])
    end
end
