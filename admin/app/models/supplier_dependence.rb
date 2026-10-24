# Where Super Génial's spending goes, by zone (Belgium, EU, US, other), to follow the dependence on the US.
# Purchases count by the country of the supplier's group, fixed costs give the current recurring picture.
class SupplierDependence
  def initialize(today: Date.current)
    @today = today
  end

  def period = (@today - 1.year + 1.day)..@today

  def purchases = @purchases ||= PurchaseInvoice.issued_between(period).includes(:supplier).to_a

  def by_zone(purchases = self.purchases)
    totals = purchases.group_by(&:zone).transform_values { |zone_purchases| zone_purchases.sum { |purchase| purchase.sign * purchase.amount } }
    Country::ZONES.keys.index_with { |zone| totals.fetch(zone, 0) }
  end

  def total = by_zone.values.sum

  def share(zone, totals = by_zone)
    sum = totals.values.sum
    sum.zero? ? nil : (totals[zone] / sum * 100).round(1)
  end

  # The last four quarters, oldest first, with the US share of each.
  def quarters
    4.downto(1).map do |offset|
      start = (@today.beginning_of_quarter << (3 * (offset - 1)))
      range = start..start.end_of_quarter
      totals = by_zone(purchases.select { |purchase| range.cover?(purchase.issued_on) })
      { label: "T#{(start.month - 1) / 3 + 1} #{start.year}", totals:, us_share: share("us", totals) }
    end
  end

  def top_suppliers(zone, limit: 5)
    purchases.select { |purchase| purchase.zone == zone && purchase.supplier }.group_by(&:supplier)
      .map { |supplier, rows| { supplier:, amount: rows.sum { |purchase| purchase.sign * purchase.amount } } }
      .sort_by { |row| -row[:amount] }.first(limit)
  end

  # Fixed costs per month, by zone; costs without a supplier cannot be placed.
  def fixed_costs_by_zone
    costs = FixedCost.active.includes(:supplier).group_by { |cost| cost.supplier&.zone || "unknown" }
    costs.transform_values { |zone_costs| zone_costs.sum(&:monthly_amount) }
  end
end
