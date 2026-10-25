# The seller printed on every invoice: Marco & Vespucci SRL, trading as Super Génial. A single row.
class CompanyProfile < ApplicationRecord
  normalizes :vat_number, with: ->(number) { number.upcase.gsub(/[^A-Z0-9]/, "") }
  normalizes :iban, :bic, with: ->(value) { value.upcase.gsub(/\s/, "") }

  validates :legal_name, presence: true
  validates :payment_terms_days, numericality: { only_integer: true, in: 0..120 }
  validates :last_external_number, format: { with: /\A\d{4}-\d{3,}\z/, message: "doit ressembler à 2026-042" }, allow_blank: true

  def self.current = first_or_create!(legal_name: "Marco & Vespucci SRL", trade_name: "Super Génial")

  # Belgian enterprise number (BCE), the VAT number without its country prefix.
  def enterprise_number = vat_number.to_s.start_with?("BE") ? vat_number.delete_prefix("BE") : nil

  def formatted_enterprise_number = enterprise_number&.then { |number| number.sub(/\A(\d{4})(\d{3})(\d{3})\z/, '\1.\2.\3') }

  def peppol_id = enterprise_number && "0208:#{enterprise_number}"

  MISSING_FOR_INVOICING = %i[ vat_number street postal_code city iban ].freeze

  def missing_for_invoicing = MISSING_FOR_INVOICING.select { |attribute| public_send(attribute).blank? }

  def ready_for_invoicing? = missing_for_invoicing.empty?

  def snapshot
    slice(:legal_name, :trade_name, :vat_number, :street, :postal_code, :city, :country, :email, :phone, :website, :iban, :bic, :invoice_footer)
      .merge("enterprise_number" => formatted_enterprise_number)
  end

  def to_s = trade_name.presence || legal_name
end
