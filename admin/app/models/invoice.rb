# A sales document of Super Génial: an invoice or a credit note.
# Issued by the admin (lines, VAT, Peppol), or a reference to an older OkiOki / Harvest document.
# amount is the total excluding VAT, negative for credit notes, so that sums give the turnover.
# With prices_include_vat, line prices are entered VAT included: the amounts excluding VAT are derived from them so
# that the total to pay is exactly the sum of the entered amounts (40 € entered, 40,00 € to pay).
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

  # Set by ClientMerge: an issued document may move to the client it was merged into (its buyer snapshot stays).
  attr_accessor :reassigning_client

  # A new line without description is a blank row of the form: its quantity, price and VAT keep their defaults, so only the
  # description tells it apart. A saved line emptied by mistake still fails validation instead of silently vanishing.
  accepts_nested_attributes_for :lines, allow_destroy: true, reject_if: ->(attributes) { attributes[:id].blank? && attributes[:description].blank? }

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

  def kept_lines = lines.reject(&:marked_for_destruction?)

  def subtotal = kept_lines.sum(&:net_amount)

  def total = amount.to_d + sign * vat_amount.to_d

  def regime = VatRegime.fetch(vat_regime)

  def vat_category = regime[:category]

  # VAT breakdown per rate, as the Peppol document and the VAT return need it.
  # Prices VAT included: the gross amounts of a rate are split into a taxable amount and the VAT that adds up to them.
  def vat_subtotals
    kept_lines.group_by(&:applied_vat_rate).map do |rate, rate_lines|
      if prices_include_vat?
        gross = rate_lines.sum(&:entered_amount)
        taxable = self.class.taxable_in(gross, rate)
        { rate:, taxable:, vat: gross - taxable }
      else
        taxable = rate_lines.sum(&:net_amount)
        { rate:, taxable:, vat: (taxable * rate / 100).round(2) }
      end
    end
  end

  # The amount excluding VAT of a line entered VAT included. Each line gets its share of the taxable amount of its rate,
  # and the rounding cents go to its largest line, so that lines always add up to the VAT breakdown.
  def net_amount_of(line)
    rate = line.applied_vat_rate
    group = kept_lines.select { |other| other.applied_vat_rate == rate }
    return (line.entered_amount / (1 + rate / 100)).round(2) unless group.any? { |other| other.equal?(line) }

    shares = group.to_h { |other| [ other.object_id, (other.entered_amount / (1 + rate / 100)).round(2) ] }
    largest = group.max_by { |other| other.entered_amount.abs }
    shares[largest.object_id] += self.class.taxable_in(group.sum(&:entered_amount), rate) - shares.values.sum
    shares.fetch(line.object_id)
  end

  # The taxable amount of a gross amount at a VAT rate. Among the cent-rounded candidates, prefer the one whose VAT,
  # computed the usual way (taxable × rate, rounded), gives back the gross amount exactly. Some gross amounts have no
  # such taxable amount (the VAT jumps by two cents there); the VAT then differs by one cent from taxable × rate,
  # which the EN 16931 rule BR-CO-17 tolerates.
  def self.taxable_in(gross, rate)
    rate = rate.to_d
    base = (gross.to_d / (1 + rate / 100)).round(2)
    [ base, base - 0.01.to_d, base + 0.01.to_d ].find { |taxable| taxable + (taxable * rate / 100).round(2) == gross } || base
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
    Invoice.new(kind: "credit_note", source: "admin", status: "draft", client:, project:, credited_invoice: self, vat_regime:, prices_include_vat:,
                issued_on: Date.current, label: "Note de crédit sur la facture #{number}").tap do |credit_note|
      lines.each { |line| credit_note.lines.build(line.slice(:position, :description, :quantity, :unit, :unit_price, :vat_rate, :period_start, :period_end)) }
    end
  end

  private
    def compute_totals
      return if kept_lines.empty?
      self.amount = sign * subtotal
      self.vat_amount = vat_subtotals.sum { |subtotal| subtotal[:vat] }
    end

    def issued_documents_are_immutable
      return unless locked?
      changed_fields = changed - MUTABLE_WHEN_ISSUED - (reassigning_client ? %w[ client_id ] : [])
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
