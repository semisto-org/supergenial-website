# Purchase category with its proposed accounting treatment (PCMN account, VAT and income tax deductibility).
# validated_at is set once the accountant has checked the line.
class ExpenseCategory < ApplicationRecord
  include Commentable

  has_many :suppliers, dependent: :restrict_with_error
  has_many :purchase_invoices, dependent: :restrict_with_error

  validates :key, :name, presence: true
  validates :key, uniqueness: true
  validates :vat_deductible_percent, :tax_deductible_percent, numericality: { in: 0..100 }
  validates :vat_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { order(:position, :name) }

  def validated? = validated_at.present?

  def to_s = name
end
