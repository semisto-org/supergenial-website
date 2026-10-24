# Ce qu'un client paie de manière récurrente : maintenance, hébergement, nom de domaine…
class Contract < ApplicationRecord
  include Commentable
  include Choices
  include Periodic

  belongs_to :client
  belongs_to :project, optional: true
  belongs_to :fixed_cost, optional: true
  belongs_to :plan, optional: true

  KINDS = { "maintenance" => "Maintenance", "hebergement" => "Hébergement", "nom_de_domaine" => "Nom de domaine",
            "abonnement" => "Abonnement", "refacturation" => "Refacturation", "autre" => "Autre" }.freeze

  choices :status, actif: "Actif", suspendu: "Suspendu", termine: "Terminé"

  validates :label, presence: true
  validates :kinds, presence: { message: "choisir au moins un type" }
  validate :kinds_are_known
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :amount, presence: true, unless: :plan

  before_validation :follow_plan_period

  # Un contrat a un ou plusieurs types, stockés en liste JSON.
  scope :of_kind, ->(kind) { where("EXISTS (SELECT 1 FROM json_each(contracts.kinds) WHERE value = ?)", kind) }
  scope :due_by, ->(date) { actif.where(next_billing_on: ..date) }
  scope :by_due_date, -> { order(Arel.sql("next_billing_on IS NULL"), :next_billing_on) }

  def self.kind_options = KINDS.invert.to_a

  # Les cases cochées arrivent avec une valeur vide : on la retire et on garde l'ordre de KINDS.
  def kinds=(values)
    values = Array(values).compact_blank.map(&:to_s).uniq
    super(values.sort_by { |kind| KINDS.keys.index(kind) || KINDS.size })
  end

  def kind?(kind) = kinds.include?(kind.to_s)

  def maintenance? = kind?(:maintenance)

  def kinds_label = kinds.map { |kind| KINDS[kind] }.join(" + ")

  # Relié à une formule, le contrat suit son prix du moment, sauf prix négocié (amount).
  def amount_on(date = Date.current) = amount || plan&.price_on(date) || 0

  def current_amount = amount_on(Date.current)

  def negotiated? = plan.present? && amount.present?

  # Le prochain changement de prix de la formule qui touche ce contrat.
  def next_plan_price = (plan&.next_price unless negotiated?)

  def monthly_amount = monthly(current_amount)

  def yearly_amount = yearly(current_amount)

  # Ce que le contrat rapporte sur les 12 prochains mois, hausses de prix programmées comprises.
  def revenue_over_next_year(from = Date.current)
    return yearly_amount if period == "annuel"
    12.times.sum { |month| amount_on(from + month.months) }
  end

  def yearly_cost = yearly(cost)

  def yearly_margin = yearly_amount - yearly_cost

  def margin_rate
    return if yearly_amount.zero?
    (yearly_margin / yearly_amount * 100).round(1)
  end

  def due?(on = Date.current) = actif? && next_billing_on.present? && next_billing_on <= on

  # Enregistre la facture OkiOki de l'échéance et avance la prochaine d'une période.
  def bill!(on: Date.current, number: nil)
    base = next_billing_on || on
    transaction do
      invoice = client.invoices.create!(project:, number:, issued_on: on, amount: amount_on(base),
                                        label: "#{label} (#{I18n.l(base, format: :month)})")
      update!(last_billed_on: on, next_billing_on: period == "annuel" ? base.next_year : base.next_month)
      invoice
    end
  end

  def to_s = label

  private
    def kinds_are_known
      errors.add(:kinds, "contient un type inconnu") if (kinds - KINDS.keys).any?
    end

    # Au prix du catalogue, la périodicité est celle de la formule ; un prix négocié garde la sienne.
    def follow_plan_period
      self.period = plan.period if plan && amount.nil?
    end
end
