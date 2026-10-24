# A dated, sourced tax figure (rates, ceilings). A new value starts on valid_from; the old one stays for past years.
# verified_at is set once the accountant has confirmed the figure.
class TaxParameter < ApplicationRecord
  validates :key, :label, :valid_from, presence: true
  validates :value, numericality: true
  validates :valid_from, uniqueness: { scope: :key }

  scope :ordered, -> { order(:key, valid_from: :desc) }

  def self.value(key, on: Date.current)
    where(key: key.to_s, valid_from: ..on).order(valid_from: :desc).pick(:value) or raise KeyError, "Paramètre fiscal manquant : #{key}"
  end

  # The value in force on that day for each key.
  def self.in_force(on: Date.current) = where(valid_from: ..on).ordered.to_a.uniq(&:key)

  def verified? = verified_at.present?

  def to_s = label
end
