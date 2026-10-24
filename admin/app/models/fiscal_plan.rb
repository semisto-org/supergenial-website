# What the manager plans to take from the company for a year: monthly remuneration, a year-end payment, the PLCI.
class FiscalPlan < ApplicationRecord
  validates :year, presence: true, uniqueness: true
  validates :monthly_remuneration, :year_end_remuneration, :plci_amount, numericality: { greater_than_or_equal_to: 0 }

  def self.for(year) = find_or_initialize_by(year:)
end
