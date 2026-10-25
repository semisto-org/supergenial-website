# One run of a history import (Harvest API, OkiOki CSV), with its report. Dry runs change nothing.
class ImportRun < ApplicationRecord
  include Choices

  choices :kind, harvest: "Harvest", okioki: "OkiOki"
  choices :status, pending: "En attente", running: "En cours", done: "Terminé", failed: "Échec"

  belongs_to :user, optional: true, default: -> { Current.user }

  scope :recent, -> { order(created_at: :desc) }

  def to_s = "#{kind_label} du #{I18n.l(created_at, format: :short)}"
end
