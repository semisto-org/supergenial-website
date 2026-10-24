class Project < ApplicationRecord
  include Commentable
  include Choices

  belongs_to :client
  has_many :time_entries, dependent: :nullify
  has_many :contracts, dependent: :nullify
  has_many :invoices, dependent: :nullify

  choices :kind, application: "Application", site: "Site web", mise_a_jour: "Mise à jour",
                 prestation: "Prestation", autre: "Autre"
  choices :billing_mode, forfait: "Forfait", regie: "Régie", pack: "Pack d'heures"
  choices :status, devis: "Devis", non_signe: "Non signé", en_attente: "En attente", en_cours: "En cours",
                   maintenance: "Maintenance", termine: "Terminé", abandonne: "Abandonné"

  validates :name, presence: true

  scope :ongoing, -> { where(status: %w[devis en_attente en_cours maintenance]) }

  def rate(date = Date.current) = hourly_rate || client.rate(date)

  def hours_spent = time_entries.sum(:hours)

  def invoiced = invoices.sum(:amount)

  def to_s = name
end
