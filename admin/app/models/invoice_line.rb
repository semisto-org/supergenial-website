class InvoiceLine < ApplicationRecord
  UNITS = { "unit" => [ "pièce", "C62" ], "hour" => [ "h", "HUR" ], "day" => [ "j", "DAY" ], "month" => [ "mois", "MON" ], "year" => [ "an", "ANN" ] }.freeze

  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, numericality: { other_than: 0 }
  validates :unit_price, numericality: true
  validates :vat_rate, inclusion: { in: VatRegime::RATES }
  validates :unit, inclusion: { in: UNITS.keys }
  validate :invoice_is_editable

  def net_amount = (quantity * unit_price).round(2)

  def unit_label = UNITS.dig(unit, 0)

  def unit_code = UNITS.dig(unit, 1)

  def to_s = description

  private
    def invoice_is_editable
      errors.add(:base, "La facture est émise : elle ne se modifie plus.") if invoice&.locked? && (changed? || marked_for_destruction?)
    end
end
