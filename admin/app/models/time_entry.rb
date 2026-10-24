class TimeEntry < ApplicationRecord
  include Choices

  belongs_to :client
  belongs_to :project, optional: true
  belongs_to :pack, optional: true
  belongs_to :invoice, optional: true

  choices :status, a_facturer: "À facturer", facture: "Facturé", au_pack: "Imputé au pack", offert: "Offert"

  validates :performed_on, presence: true
  validates :hours, numericality: { greater_than: 0 }
  validate :project_and_pack_belong_to_client

  before_validation :status_from_pack

  scope :recent, -> { order(performed_on: :desc, id: :desc) }

  def rate = project&.rate(performed_on) || client.rate(performed_on)

  def amount = hours * rate

  private
    def status_from_pack
      self.status = "au_pack" if pack.present?
    end

    def project_and_pack_belong_to_client
      errors.add(:project, "n'appartient pas à ce client") if project && project.client_id != client_id
      errors.add(:pack, "n'appartient pas à ce client") if pack && pack.client_id != client_id
    end
end
