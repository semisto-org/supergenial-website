# Une facture émise dans OkiOki : l'admin ne la génère pas, elle la référence.
class Invoice < ApplicationRecord
  include Commentable
  belongs_to :client
  belongs_to :project, optional: true
  has_many :time_entries
  has_many :packs, dependent: :nullify

  before_destroy :release_time_entries

  validates :label, :issued_on, :amount, presence: true

  scope :in_year, ->(year) { where(issued_on: Date.new(year).all_year) }
  scope :unpaid, -> { where(paid_on: nil) }
  scope :recent, -> { order(issued_on: :desc) }

  def paid? = paid_on.present?

  def to_s = [ number, label ].compact_blank.join(" · ")

  private
    # Supprimer la facture annule la facturation : ses heures repassent « à facturer ».
    def release_time_entries
      time_entries.facture.update_all(status: "a_facturer")
      time_entries.update_all(invoice_id: nil)
    end
end
