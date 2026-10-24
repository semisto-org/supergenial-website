# Un frais fixe de Super Génial (outil, serveur, abonnement).
# forecast_amount : ce que le frais coûtera après les changements prévus (nil = inchangé, 0 = supprimé).
class FixedCost < ApplicationRecord
  include Commentable
  include Choices
  include Periodic

  belongs_to :supplier, optional: true
  has_many :contracts, dependent: :nullify

  choices :category, ia: "IA", outils: "Outils", hebergement: "Hébergement", serveurs: "Serveurs",
                     telecom: "Télécom", autre: "Autre"

  validates :name, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }

  def monthly_amount = monthly(amount)

  def yearly_amount = yearly(amount)

  def forecast = forecast_amount.nil? ? amount : forecast_amount

  def monthly_forecast = monthly(forecast)

  def to_s = name
end
