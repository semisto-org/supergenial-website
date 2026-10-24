# Une formule d'abonnement du catalogue (Essentiel, Évolution…) et l'historique de ses prix.
class Plan < ApplicationRecord
  include Commentable
  include Periodic

  has_many :prices, -> { order(:starts_on) }, class_name: "PlanPrice", dependent: :destroy, inverse_of: :plan
  has_many :contracts, dependent: :restrict_with_error

  accepts_nested_attributes_for :prices

  validates :name, presence: true, uniqueness: true
  validates :prices, presence: { message: "doit avoir un premier prix" }

  scope :ordered, -> { order(:position, :name) }
  scope :active, -> { where(active: true) }

  # Le prix en vigueur à une date : le dernier prix activé ce jour-là ou avant.
  def price_on(date = Date.current) = prices.select { |price| price.starts_on <= date }.last&.amount

  def current_price = price_on

  # Le prochain changement de prix programmé, s'il y en a un.
  def next_price(after = Date.current) = prices.find { |price| price.starts_on > after }

  def active_contracts = contracts.select(&:actif?)

  def yearly_revenue = active_contracts.sum(&:yearly_amount)

  def to_s = name
end
