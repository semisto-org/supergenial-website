# The time entries of one client over a period, as sent to the client: every entry whatever its billing status,
# with totals per project and the state of the prepaid packs drawn on.
class TimeReport
  attr_reader :client, :from, :to, :project

  def initialize(client:, from:, to:, project: nil, with_amounts: false)
    raise ArgumentError, "La date de fin précède la date de début." if from > to
    raise ArgumentError, "Ce projet n'appartient pas à #{client}." if project && project.client_id != client.id

    @client, @from, @to, @project, @with_amounts = client, from, to, project, with_amounts
  end

  # Defaults to the previous calendar month, the usual period of a statement.
  def self.default_period(today = Date.current)
    last_month = today.prev_month
    [ last_month.beginning_of_month, last_month.end_of_month ]
  end

  def with_amounts? = @with_amounts

  def entries
    @entries ||= begin
      scope = client.time_entries.where(performed_on: from..to).includes(:pack, project: :client).order(:performed_on, :id)
      scope = scope.where(project:) if project
      scope.to_a
    end
  end

  def empty? = entries.empty?

  def total_hours = entries.sum(&:hours)

  # Value of the hours paid by the hour: prepaid (pack) and offered hours are worth nothing more.
  def billable?(entry) = !entry.au_pack? && !entry.offert?

  def amount(entry) = billable?(entry) ? entry.amount : 0

  def total_amount = entries.sum { |entry| amount(entry) }

  def offered_hours = entries.select(&:offert?).sum(&:hours)

  # Hours per project, in order of first appearance; entries without a project are grouped under nil.
  def project_totals = entries.group_by(&:project).transform_values { |group| group.sum(&:hours) }

  def several_projects? = project.nil? && entries.map(&:project_id).uniq.size > 1

  def packs = entries.filter_map(&:pack).uniq

  def filename = "releve-heures-#{client.name.parameterize}-#{from.iso8601}-#{to.iso8601}.pdf"
end
