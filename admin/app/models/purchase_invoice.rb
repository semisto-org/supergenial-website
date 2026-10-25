# An invoice or credit note received by Super Génial: through Peppol (Recommand inbox), by e-mail
# (the purchases mailbox, read by Claude) or added by hand. It is checked, then booked.
# amount (excluding VAT) and vat_amount are in euros and positive for both kinds: kind gives the sign.
# original_amount is the amount excluding VAT in the invoice currency, converted with exchange_rate.
class PurchaseInvoice < ApplicationRecord
  include Commentable
  include Choices
  include VatDeclared

  DOCUMENT_TYPES = %w[ application/pdf image/png image/jpeg ].freeze
  MAX_DOCUMENT_SIZE = 15.megabytes

  choices :kind, invoice: "Facture", credit_note: "Note de crédit"
  choices :status, to_review: "À vérifier", booked: "Comptabilisée"
  choices :source, peppol: "Peppol", email: "E-mail", manual: "Ajout manuel"
  choices :vat_regime, **PurchaseVatRegime.labels.symbolize_keys

  belongs_to :supplier, optional: true
  belongs_to :expense_category, optional: true
  belongs_to :fixed_cost, optional: true
  has_one_attached :document

  normalizes :currency, :seller_country, with: ->(code) { code.strip.upcase }
  normalizes :seller_vat_number, with: ->(number) { number.upcase.gsub(/[^A-Z0-9]/, "") }

  before_validation :apply_category_defaults, if: -> { will_save_change_to_expense_category_id? && !will_save_change_to_vat_deductible_percent? }
  before_validation :convert_to_euros, if: -> { foreign_currency? && original_amount.present? }
  before_validation -> { self.original_amount = amount }, unless: :foreign_currency?

  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :amount, :vat_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :exchange_rate, numericality: { greater_than: 0 }
  validates :vat_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :vat_deductible_percent, numericality: { in: 0..100 }
  validates :base_grid, inclusion: { in: PurchaseVatRegime::BASE_GRIDS.keys }
  validates :supplier, :expense_category, :number, :issued_on, presence: true, if: :booked?
  validate :document_is_acceptable

  scope :recent, -> { order(Arel.sql("issued_on IS NULL DESC"), issued_on: :desc, id: :desc) }
  scope :issued_between, ->(range) { where(issued_on: range) }

  def self.matching_supplier(vat_number: nil, name: nil)
    vat_number = vat_number.to_s.upcase.gsub(/[^A-Z0-9]/, "")
    (Supplier.find_by(vat_number:) if vat_number.present?) ||
      (Supplier.where("lower(name) = ?", name.to_s.strip.downcase).first if name.present?)
  end

  def sign = credit_note? ? -1 : 1

  def total = amount.to_d + vat_amount.to_d

  def foreign_currency? = currency.present? && currency != "EUR"

  def regime = PurchaseVatRegime.fetch(vat_regime)

  def reverse_charge? = regime[:reverse_charge].present?

  # Under reverse charge, the supplier charges no VAT: Super Génial declares it and deducts it.
  def self_assessed_vat = reverse_charge? ? (amount.to_d * vat_rate.to_d / 100).round(2) : 0

  def deductible_vat = ((reverse_charge? ? self_assessed_vat : vat_amount.to_d) * vat_deductible_percent.to_d / 100).round(2)

  def country = supplier&.billing_country || seller_country

  def zone = supplier&.zone || Country.zone(country)

  # Belgian suppliers must invoice through Peppol: an e-mailed invoice means asking them to switch.
  def peppol_missing?
    return false if peppol?
    supplier ? supplier.peppol_expected? : seller_country == "BE"
  end

  def extraction_pending? = extraction_status == "pending"

  # Attaches a supplier found by VAT number or name and takes its default category.
  def match_supplier
    self.supplier ||= self.class.matching_supplier(vat_number: seller_vat_number, name: seller_name)
    self.expense_category ||= supplier&.expense_category
    self.vat_regime = PurchaseVatRegime.suggest(country:, vat_amount:) if supplier && vat_regime == "domestic" && vat_amount.to_d.zero?
    self
  end

  # Fills the blank fields with what Claude read on the document; what someone already typed wins.
  def apply_extraction(data)
    data = data.to_h.stringify_keys
    self.extraction = data
    self.kind = "credit_note" if data["document_type"] == "credit_note"
    { "invoice_number" => :number, "issue_date" => :issued_on, "due_date" => :due_on, "supplier_name" => :seller_name,
      "supplier_vat_number" => :seller_vat_number, "supplier_country" => :seller_country }.each do |key, attribute|
      public_send("#{attribute}=", data[key]) if public_send(attribute).blank? && data[key].present?
    end
    self.currency = data["currency"] if data["currency"].present? && amount.to_d.zero?
    if amount.to_d.zero? && data["net_amount"]
      self.original_amount = data["net_amount"].to_d.abs
      self.amount = original_amount unless foreign_currency?
    end
    self.vat_amount = data["vat_amount"].to_d.abs if vat_amount.to_d.zero? && data["vat_amount"] && !foreign_currency?
    match_supplier
    self.vat_regime = PurchaseVatRegime.suggest(country:, vat_amount: data["vat_amount"]) if data["reverse_charge"] || data["vat_amount"].to_d.zero?
    self
  end

  def book! = update!(status: "booked", booked_at: Time.current)

  def reopen! = update!(status: "to_review", booked_at: nil)

  def to_s = [ supplier&.name || seller_name || "Fournisseur à identifier", number ].compact.join(" · ")

  private
    def apply_category_defaults
      self.vat_deductible_percent = expense_category.vat_deductible_percent if expense_category
    end

    def convert_to_euros
      self.amount = (original_amount * exchange_rate).round(2)
    end

    def document_is_acceptable
      return unless document.attached? && attachment_changes["document"]
      errors.add(:document, "doit être un PDF ou une image") unless document.blob.content_type.in?(DOCUMENT_TYPES)
      errors.add(:document, "est trop lourd (15 Mo maximum)") if document.blob.byte_size > MAX_DOCUMENT_SIZE
    end
end
