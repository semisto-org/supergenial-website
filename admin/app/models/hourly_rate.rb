# Le taux horaire standard, en vigueur à partir de starts_on jusqu'au taux suivant.
# Un taux propre au client ou au projet prime sur lui.
class HourlyRate < ApplicationRecord
  # Sans aucun taux encodé (base vide), on retombe sur le taux historique.
  FALLBACK = 80

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :starts_on, presence: true, uniqueness: { message: "a déjà un taux à cette date" }

  after_commit { Current.hourly_rates = nil }

  scope :chronological, -> { order(:starts_on) }

  # Les taux sont lus une fois par requête : une liste d'heures en demande un par ligne.
  def self.cached = Current.hourly_rates ||= chronological.to_a

  # Le taux en vigueur à une date : le dernier activé ce jour-là ou avant.
  def self.on(date = Date.current)
    (cached.select { |rate| rate.starts_on <= date }.last || cached.first)&.amount || FALLBACK
  end

  # Le prochain changement de taux programmé, s'il y en a un.
  def self.next_change(after = Date.current) = cached.find { |rate| rate.starts_on > after }

  def current? = self.class.cached.select { |rate| rate.starts_on <= Date.current }.last == self

  def upcoming? = starts_on > Date.current
end
