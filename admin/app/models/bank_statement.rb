# A bank statement imported from a CODA file (Belfius), kept with its original file for the accountant.
class BankStatement < ApplicationRecord
  include Commentable

  belongs_to :user, optional: true
  has_many :transactions, -> { order(:sequence) }, class_name: "BankTransaction", dependent: :destroy, inverse_of: :bank_statement
  has_one_attached :file

  validates :iban, :number, :statement_on, :digest, presence: true
  validates :digest, uniqueness: { message: "est déjà importé (même fichier)" }

  scope :recent, -> { order(statement_on: :desc, number: :desc) }

  def movements_total = transactions.sum(&:amount)

  # The movements must explain the change of balance; otherwise the file is incomplete.
  def balanced? = opening_balance + movements_total == closing_balance

  def to_s = "Extrait #{number} du #{I18n.l(statement_on)}"
end
