class Client < ApplicationRecord
  include Commentable
  include Choices

  # Les factures comptent dans le chiffre d'affaires : un client facturé ne se supprime pas,
  # il passe en « Ancien client ». Sans facture, il part avec tout ce qui le concerne.
  has_many :invoices, dependent: :restrict_with_error
  has_many :contacts, -> { order(primary: :desc, first_name: :asc, last_name: :asc) }, dependent: :destroy
  has_many :time_entries, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :packs, dependent: :destroy

  choices :kind, organisation: "Organisation", particulier: "Particulier"
  choices :status, actif: "Actif", prospect: "Prospect", ancien: "Ancien client"

  normalizes :vat_number, with: ->(number) { number.upcase.gsub(/[^A-Z0-9]/, "") }
  normalizes :country, with: ->(code) { code.strip.upcase }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :country, inclusion: { in: Country::NAMES.keys }
  validates :billing_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :peppol_id, format: { with: /\A\d{4}:[A-Za-z0-9]+\z/, message: "doit ressembler à 0208:0123456789" }, allow_blank: true

  scope :alphabetical, -> { order(Arel.sql("LOWER(name)")) }

  def primary_contact = contacts.first

  # Sans taux propre, le client suit le taux standard en vigueur à la date de la prestation.
  def rate(date = Date.current) = hourly_rate || HourlyRate.on(date)

  def unbilled_hours = time_entries.a_facturer.sum(:hours)

  def unbilled_amount = time_entries.a_facturer.includes(:project).sum(&:amount)

  # A Belgian company: Peppol is mandatory, e-mailed invoices are not valid since 2026.
  def belgian_business? = country == "BE" && vat_number.to_s.start_with?("BE")

  def enterprise_number = vat_number.to_s.start_with?("BE") ? vat_number.delete_prefix("BE") : nil

  # The usual Peppol address of a Belgian company, to be confirmed with a directory lookup.
  def suggested_peppol_id = peppol_id.presence || (enterprise_number && "0208:#{enterprise_number}")

  def invoicing_email = billing_email.presence || primary_contact&.email.presence

  def invoicing_address_complete? = [ street, postal_code, city, country ].all?(&:present?)

  def invoicing_snapshot
    slice(:name, :vat_number, :street, :postal_code, :city, :country, :peppol_id).merge("email" => invoicing_email)
  end

  def to_s = name
end
