class BankTransactionsController < ApplicationController
  before_action :set_bank_transaction, except: :index

  def index
    @status = params[:status].presence_in(BankTransaction::STATUSES.keys)
    @bank_transactions = BankTransaction.recent.includes(:invoice, :purchase_invoice)
    @bank_transactions = @bank_transactions.where(status: @status) if @status
    @bank_transactions = @bank_transactions.limit(300)
    @counts = BankTransaction.group(:status).count
  end

  def show
  end

  def match
    document = case params[:document_type]
    when "Invoice" then Invoice.find(params[:document_id])
    when "PurchaseInvoice" then PurchaseInvoice.find(params[:document_id])
    end
    return redirect_to(@bank_transaction, alert: "Pièce inconnue.") unless document

    @bank_transaction.match!(document)
    redirect_to next_path, notice: "Mouvement rapproché."
  end

  def unmatch
    @bank_transaction.unmatch!
    redirect_to @bank_transaction, notice: "Rapprochement annulé."
  end

  def ignore
    @bank_transaction.ignore!(params[:category].presence_in(BankTransaction::CATEGORIES.keys))
    redirect_to next_path, notice: "Mouvement classé sans pièce."
  rescue ActiveRecord::RecordInvalid
    redirect_to @bank_transaction, alert: "Choisis une catégorie."
  end

  private
    def set_bank_transaction
      @bank_transaction = BankTransaction.find(params[:id])
    end

    # After a decision, straight to the next movement to reconcile.
    def next_path
      following = BankTransaction.unmatched.where.not(id: @bank_transaction.id).recent.first
      following ? bank_transaction_path(following) : bank_transactions_path
    end
end
