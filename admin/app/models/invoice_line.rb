class InvoiceLine < ApplicationRecord
  UNITS = { "unit" => [ "pièce", "C62" ], "hour" => [ "h", "HUR" ], "day" => [ "j", "DAY" ], "month" => [ "mois", "MON" ], "year" => [ "an", "ANN" ] }.freeze

  belongs_to :invoice

  validates :description, presence: true
  validates :quantity, numericality: { other_than: 0 }
  validates :unit_price, numericality: true
  validates :vat_rate, inclusion: { in: VatRegime::RATES }
  validates :unit, inclusion: { in: UNITS.keys }
  validate :invoice_is_editable

  # The amount as entered: excluding VAT, or VAT included when the invoice says its prices include VAT.
  def entered_amount = (quantity.to_d * unit_price.to_d).round(2)

  def net_amount = prices_include_vat? ? invoice.net_amount_of(self) : entered_amount

  # The rate that actually applies: reverse charge and exports carry no Belgian VAT.
  def applied_vat_rate = invoice.nil? || invoice.standard? ? vat_rate.to_d : 0.to_d

  # The unit price excluding VAT. Derived from a price VAT included, it keeps as many decimals as needed (up to 8) for
  # quantity × unit price to give the line amount back, as Peppol BIS 3 requires (PEPPOL-EN16931-R120).
  def net_unit_price
    return unit_price.to_d unless prices_include_vat?
    return 0.to_d if quantity.to_d.zero?
    exact = net_amount / quantity.to_d
    (2..8).each do |decimals|
      price = exact.round(decimals)
      return price if (quantity.to_d * price).round(2) == net_amount
    end
    exact.round(8)
  end

  # French plural from 2 on: "1 an", "1,5 an", "2 ans". Abbreviations (h, j) and "mois" do not change.
  def unit_label
    label = UNITS.dig(unit, 0)
    quantity.to_d.abs >= 2 && %w[ unit year ].include?(unit) ? "#{label}s" : label
  end

  def unit_code = UNITS.dig(unit, 1)

  def to_s = description

  private
    def prices_include_vat? = invoice&.prices_include_vat?

    def invoice_is_editable
      errors.add(:base, "La facture est émise : elle ne se modifie plus.") if invoice&.locked? && (changed? || marked_for_destruction?)
    end
end
