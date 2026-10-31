# A sales document of Super Génial: an invoice or a credit note.
# Issued by the admin (lines, VAT, Peppol), or a reference to an older OkiOki / Harvest document.
# amount is the total excluding VAT, negative for credit notes, so that sums give the turnover.
class Invoice < ApplicationRecord
  include Commentable
  include Choices
  include VatDeclared

  # What can still change once an admin document is issued: payment, notes and delivery tracking.
  MUTABLE_WHEN_ISSUED = %w[ paid_on notes ubl_xml peppol_status peppol_document_id sent_at send_error updated_at ].freeze

  choices :kind, invoice: "Facture", credit_note: "Note de crédit"
  choices :status, draft: "Brouillon", issued: "Émise"
  choices :source, admin: "Admin", okioki: "OkiOki", harvest: "Harvest"
  choices :vat_regime, **VatRegime.labels.symbolize_keys

  belongs_to :client
  belongs_to :project, optional: true
  belongs_to :credited_invoice, class_name: "Invoice", optional: true
  has_many :credit_notes, class_name: "Invoice", foreign_key: :credited_invoice_id, dependent: :restrict_with_error
  has_many :lines, -> { order(:position, :id) }, class_name: "InvoiceLine", dependent: :destroy, inverse_of: :invoice
  has_many :time_entries
  has_many :packs, dependent: :nullify
  # The original PDF of a document issued outside the admin (OkiOki).
  has_one_attached :document

  accepts_nested_attributes_for :lines, allow_destroy: true, reject_if: ->(attributes) { attributes[:description].blank? && attributes[:unit_price].blank? }

  before_validation :compute_totals, if: -> { admin? && !locked? }
  before_destroy :forbid_destroying_issued, prepend: true
  before_destroy :release_time_entries

  validates :label, :issued_on, :amount, presence: true
  validate :issued_documents_are_immutable
  validates :credited_invoice, presence: true, if: -> { credit_note? && admin? }

  scope :in_year, ->(year) { where(issued_on: Date.new(year).all_year) }
  scope :counted, -> { where.not(status: "draft") }
  scope :unpaid, -> { counted.where(paid_on: nil) }
  scope :recent, -> { order(issued_on: :desc, id: :desc) }

  # Issued admin documents are legal originals: they never change, a credit note corrects them.
  def locked? = admin? && issued? && status_in_database == "issued"

  def paid? = paid_on.present?

  def sign = credit_note? ? -1 : 1

  def subtotal = lines.reject(&:marked_for_destruction?).sum(&:net_amount)

  def total = amount.to_d + sign * vat_amount.to_d

  def regime = VatRegime.fetch(vat_regime)

  def vat_category = regime[:category]

  # VAT breakdown per rate, as the Peppol document and the VAT return need it.
  def vat_subtotals
    lines.reject(&:marked_for_destruction?).group_by { |line| standard? ? line.vat_rate : 0 }.map do |rate, rate_lines|
      taxable = rate_lines.sum(&:net_amount)
      { rate: rate.to_d, taxable:, vat: (taxable * rate.to_d / 100).round(2) }
    end
  end

  def to_s = [ number || ("brouillon" if draft?), label ].compact_blank.join(" · ")

  def issue!(on: Date.current)
    with_lock do
      raise ActiveRecord::RecordInvalid, self unless issuable?
      company = CompanyProfile.current
      self.number = InvoiceNumbering.next(on.year)
      self.issued_on = on
      self.issued_at = Time.current
      self.due_on = invoice? ? on + company.payment_terms_days.days : nil
      self.structured_reference = InvoiceNumbering.structured_reference(number)
      self.seller = company.snapshot
      self.buyer = client.invoicing_snapshot
      self.status = "issued"
      save!
    end
  end

  def issuable?
    errors.clear
    errors.add(:base, "Le document est déjà émis.") unless draft? && admin?
    errors.add(:lines, "manquent : ajoute au moins une ligne.") if lines.reject(&:marked_for_destruction?).empty?
    errors.add(:base, "Complète la fiche Société (#{CompanyProfile.current.missing_for_invoicing.map { |attribute| CompanyProfile.human_attribute_name(attribute) }.to_sentence}).") unless CompanyProfile.current.ready_for_invoicing?
    errors.add(:base, "Complète l'adresse du client (rue, code postal, ville, pays).") unless client.invoicing_address_complete?
    errors.add(:base, "L'autoliquidation intracommunautaire exige le n° de TVA du client.") if intra_eu? && client.vat_number.blank?
    errors.empty?
  end

  def build_credit_note
    Invoice.new(kind: "credit_note", source: "admin", status: "draft", client:, project:, credited_invoice: self, vat_regime:,
                issued_on: Date.current, label: "Note de crédit sur la facture #{number}").tap do |credit_note|
      lines.each { |line| credit_note.lines.build(line.slice(:position, :description, :quantity, :unit, :unit_price, :vat_rate, :period_start, :period_end)) }
    end
  end

  private
    def compute_totals
      kept = lines.reject(&:marked_for_destruction?)
      return if kept.empty?
      self.amount = sign * subtotal
      self.vat_amount = vat_subtotals.sum { |subtotal| subtotal[:vat] }
    end

    def issued_documents_are_immutable
      return unless locked?
      changed_fields = changed - MUTABLE_WHEN_ISSUED
      errors.add(:base, "Une facture émise ne se modifie plus : crée une note de crédit.") if changed_fields.any?
    end

    def forbid_destroying_issued
      return unless admin? && issued?
      errors.add(:base, "Une facture émise ne se supprime pas : crée une note de crédit.")
      throw :abort
    end

    # Supprimer la facture annule la facturation : ses heures repassent « à facturer ».
    def release_time_entries
      time_entries.facture.update_all(status: "a_facturer")
      time_entries.update_all(invoice_id: nil)
    end
end
