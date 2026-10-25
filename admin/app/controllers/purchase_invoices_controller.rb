class PurchaseInvoicesController < ApplicationController
  before_action :set_purchase_invoice, only: %i[ show edit update destroy book reopen extract document ubl ]

  def index
    @status = params[:status].presence_in(PurchaseInvoice::STATUSES.keys)
    @purchase_invoices = PurchaseInvoice.recent.includes(:supplier, :expense_category, document_attachment: :blob)
    @purchase_invoices = @purchase_invoices.where(status: @status) if @status
    @counts = PurchaseInvoice.group(:status).count
    @peppol_reminders = PurchaseInvoice.where.not(source: "peppol").where(issued_on: 1.year.ago..).includes(:supplier)
                                       .select(&:peppol_missing?).filter_map(&:supplier).uniq
    @collectable = Recommand::Client.configured? || Gmail::Client.configured?
  end

  def show
  end

  def new
    @purchase_invoice = PurchaseInvoice.new(issued_on: Date.current)
  end

  def create
    @purchase_invoice = PurchaseInvoice.new(purchase_invoice_params.merge(source: "manual"))
    @purchase_invoice.match_supplier
    @purchase_invoice.extraction_status = "pending" if @purchase_invoice.document.attached? && PurchaseExtraction.configured?
    if @purchase_invoice.save
      PurchaseExtractionJob.perform_later(@purchase_invoice) if @purchase_invoice.extraction_pending?
      redirect_to @purchase_invoice, notice: @purchase_invoice.extraction_pending? ? "Achat ajouté : Claude lit le document." : "Achat ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @purchase_invoice.update(purchase_invoice_params)
      redirect_to @purchase_invoice, notice: "Achat mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase_invoice.destroy
    redirect_to purchase_invoices_path, notice: "Achat supprimé.", status: :see_other
  end

  def book
    @purchase_invoice.book!
    redirect_to purchase_invoices_path(status: "to_review"), notice: "#{@purchase_invoice} comptabilisée."
  rescue ActiveRecord::RecordInvalid
    redirect_to edit_purchase_invoice_path(@purchase_invoice), alert: "Pour comptabiliser : #{@purchase_invoice.errors.full_messages.to_sentence}."
  end

  def reopen
    @purchase_invoice.reopen!
    redirect_to @purchase_invoice, notice: "Achat remis à vérifier."
  end

  def extract
    return redirect_to(@purchase_invoice, alert: "Claude n'est pas configuré (variable ANTHROPIC_API_KEY dans Coolify).") unless PurchaseExtraction.configured?
    @purchase_invoice.update!(extraction_status: "pending", extraction_error: nil)
    PurchaseExtractionJob.perform_later(@purchase_invoice)
    redirect_to @purchase_invoice, notice: "Claude relit le document."
  end

  # Fetches the new invoices from Peppol and the purchases mailbox now, instead of waiting for the next half hour.
  def collect
    PurchaseInboxJob.perform_later
    redirect_to purchase_invoices_path, notice: "Relève lancée : les nouvelles factures apparaissent dans une minute."
  end

  # Documents go through the admin, behind the login, never through public Active Storage URLs.
  def document
    return head :not_found unless @purchase_invoice.document.attached?
    blob = @purchase_invoice.document.blob
    send_data blob.download, filename: blob.filename.to_s, type: blob.content_type, disposition: params[:download] ? "attachment" : "inline"
  end

  def ubl
    return head :not_found if @purchase_invoice.ubl_xml.blank?
    send_data @purchase_invoice.ubl_xml, filename: "#{@purchase_invoice.number.presence || @purchase_invoice.id}.xml", type: "application/xml"
  end

  private
    def set_purchase_invoice
      @purchase_invoice = PurchaseInvoice.find(params[:id])
    end

    def purchase_invoice_params
      params.expect(purchase_invoice: %i[ document supplier_id expense_category_id fixed_cost_id kind number issued_on due_on paid_on currency
                                          original_amount exchange_rate amount vat_amount vat_regime vat_rate base_grid vat_deductible_percent notes ])
    end
end
