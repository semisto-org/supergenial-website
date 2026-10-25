class TimeEntry < ApplicationRecord
  include Choices

  belongs_to :client
  belongs_to :project, optional: true
  belongs_to :pack, optional: true
  belongs_to :invoice, optional: true

  choices :status, a_facturer: "À facturer", facture: "Facturé", au_pack: "Imputé au pack", offert: "Offert"

  validates :performed_on, presence: true
  validates :hours, numericality: { greater_than: 0 }
  validate :project_and_pack_belong_to_client

  before_validation :status_from_pack

  scope :recent, -> { order(performed_on: :desc, id: :desc) }

  # Groups unbilled entries of a single client into one draft invoice, one line per entry.
  def self.bill!(entries)
    entries = entries.to_a
    raise ArgumentError, "Coche au moins une prestation à facturer." if entries.empty?
    raise ArgumentError, "Une facture ne peut concerner qu'un seul client." if entries.map(&:client_id).uniq.size > 1

    client = entries.first.client
    hours = ActiveSupport::NumberHelper.number_to_rounded(entries.sum(&:hours), precision: 2, strip_insignificant_zeros: true, separator: ",")
    transaction do
      client.invoices.create!(
        source: "admin", status: "draft", issued_on: Date.current, vat_regime: VatRegime.suggest(client),
        project: entries.map(&:project).uniq.one? ? entries.first.project : nil,
        label: "Prestations en régie (#{hours} h)",
        lines_attributes: entries.sort_by(&:performed_on).each_with_index.map { |entry, index| entry.invoice_line_attributes(index) }
      ).tap { |invoice| entries.each { |entry| entry.update!(status: "facture", invoice:) } }
    end
  end

  def rate = project&.rate(performed_on) || client.rate(performed_on)

  def amount = hours * rate

  def invoice_line_attributes(position)
    { position:, description: [ I18n.l(performed_on), description.presence || "Prestation" ].join(" · "),
      quantity: hours, unit: "hour", unit_price: rate, vat_rate: 21 }
  end

  private
    def status_from_pack
      self.status = "au_pack" if pack.present?
    end

    def project_and_pack_belong_to_client
      errors.add(:project, "n'appartient pas à ce client") if project && project.client_id != client_id
      errors.add(:pack, "n'appartient pas à ce client") if pack && pack.client_id != client_id
    end
end
