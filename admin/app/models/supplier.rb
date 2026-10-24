# A supplier of Super Génial. billing_country is the entity that invoices us,
# group_country the country of its parent group (e.g. an Irish subsidiary of a US group).
class Supplier < ApplicationRecord
  include Commentable

  belongs_to :expense_category, optional: true
  has_many :fixed_costs, dependent: :nullify

  normalizes :vat_number, with: ->(number) { number.upcase.gsub(/[^A-Z0-9]/, "") }
  normalizes :iban, with: ->(iban) { iban.upcase.gsub(/\s/, "") }
  normalizes :billing_country, :group_country, with: ->(code) { code.strip.upcase }

  validates :name, presence: true
  validates :billing_country, inclusion: { in: Country::NAMES.keys }
  validates :group_country, inclusion: { in: Country::NAMES.keys }, allow_blank: true
  validates :website, format: { with: /\A#{URI::DEFAULT_PARSER.make_regexp(%w[ http https ])}\z/, message: "doit commencer par https://" }, allow_blank: true

  scope :alphabetical, -> { order(:name) }
  scope :active, -> { where(active: true) }

  def belgian? = billing_country == "BE"

  # The group decides where the money and the dependency really go.
  def ultimate_country = group_country.presence || billing_country

  def zone = Country.zone(ultimate_country)

  def zone_label = Country::ZONES[zone]

  # Belgian suppliers must invoice through Peppol (mandatory B2B e-invoicing since 2026).
  def peppol_expected? = require_peppol? || belgian?

  def to_s = name
end
