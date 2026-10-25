# A closed VAT quarter: what was declared, frozen. It is never reopened: a correction goes into a later quarter.
class VatPeriod < ApplicationRecord
  include Commentable

  belongs_to :closed_by, class_name: "User", optional: true
  has_many :invoices, dependent: :restrict_with_error
  has_many :purchase_invoices, dependent: :restrict_with_error

  validates :year, :quarter, presence: true
  validates :quarter, inclusion: { in: 1..4 }, uniqueness: { scope: :year }

  def readonly? = persisted? && (changed - %w[ notes updated_at ]).any?

  def to_quarter = VatReturn::Quarter.new(year:, quarter:)

  def to_s = "TVA #{to_quarter.label}"
end
