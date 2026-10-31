# A movement on the bank account. It is reconciled with what it pays (a sales invoice, a purchase invoice),
# or put in a category when no invoice explains it (salary, taxes, internal transfer…).
# amount is signed: positive for money in, negative for money out.
# It comes from a CODA statement or, read every day, from a bank connection (Enable Banking).
class BankTransaction < ApplicationRecord
  include Commentable
  include Choices

  choices :status, unmatched: "À rapprocher", matched: "Rapprochée", ignored: "Sans pièce"
  choices :category, validate: { allow_nil: true },
          remuneration: "Rémunération du gérant", taxes: "Impôts et précompte", social: "Cotisations sociales",
          vat: "TVA (paiement ou remboursement)", bank_fees: "Frais bancaires", transfer: "Transfert interne",
          capital: "Capital, prêt, compte courant", other: "Autre"

  belongs_to :bank_statement, optional: true
  belongs_to :bank_connection, optional: true
  belongs_to :invoice, optional: true
  belongs_to :purchase_invoice, optional: true

  validates :booked_on, :amount, presence: true
  validates :category, presence: true, if: :ignored?

  scope :recent, -> { order(booked_on: :desc, id: :desc) }

  def credit? = amount.positive?

  def reconciled_with = invoice || purchase_invoice

  # Sales invoices for money in, purchases for money out, closest first.
  def candidates
    credit? ? sales_candidates : purchase_candidates
  end

  def match!(document)
    transaction do
      case document
      when Invoice then update!(invoice: document, purchase_invoice: nil, status: "matched", category: nil)
      when PurchaseInvoice then update!(purchase_invoice: document, invoice: nil, status: "matched", category: nil)
      end
      document.update!(paid_on: booked_on) if document.paid_on.nil?
    end
  end

  def unmatch!
    transaction do
      document = reconciled_with
      update!(invoice: nil, purchase_invoice: nil, status: "unmatched")
      document&.update!(paid_on: nil) if document&.paid_on == booked_on
    end
  end

  def ignore!(category) = update!(status: "ignored", category:, invoice: nil, purchase_invoice: nil)

  # The automatic pass at import: structured reference, then exact amount with the number in the communication.
  def auto_match
    document = credit? ? auto_sales_match : auto_purchase_match
    match!(document) if document
    document
  end

  def label = counterparty_name.presence || communication.to_s.truncate(60).presence || transaction_code

  private
    def digits(value) = value.to_s.gsub(/\D/, "")

    def sales_candidates
      Invoice.unpaid.includes(:client).to_a.sort_by { |invoice| [ (invoice.total - amount).abs, -(invoice.issued_on&.jd || 0) ] }.first(8)
    end

    def purchase_candidates
      PurchaseInvoice.where(paid_on: nil).includes(:supplier).to_a.sort_by { |purchase| [ (purchase.sign * purchase.total + amount).abs, -(purchase.issued_on&.jd || 0) ] }.first(8)
    end

    def auto_sales_match
      if structured_reference.present?
        found = Invoice.unpaid.find { |invoice| digits(invoice.structured_reference) == digits(structured_reference) }
        return found if found
      end
      only(Invoice.unpaid.select { |invoice| invoice.total == amount && mentions?(invoice.number) })
    end

    def auto_purchase_match
      only(PurchaseInvoice.where(paid_on: nil).includes(:supplier).select do |purchase|
        purchase.sign * purchase.total == -amount && (mentions?(purchase.number) || same_iban?(purchase.supplier))
      end)
    end

    # Several documents with the same amount: a person chooses.
    def only(documents) = documents.one? ? documents.first : nil

    def mentions?(number) = number.present? && communication.to_s.include?(number)

    def same_iban?(supplier) = supplier&.iban.present? && supplier.iban == counterparty_iban.to_s.upcase.delete(" ")
end
