# How VAT applies to a purchase, and the grids of the Belgian VAT return it lands in.
# Base grids: 81 goods for resale, 82 services and other goods, 83 investments.
# Reverse charge: the supplier invoices without VAT, Super Génial declares it (grid 55 or 56) and deducts it (grid 59).
module PurchaseVatRegime
  REGIMES = {
    "domestic" => { label: "TVA facturée par le fournisseur" },
    "intra_eu_services" => { label: "Services d'un autre pays de l'UE (autoliquidation)", reverse_charge: true, base_grid: "88", due_grid: "55" },
    "intra_eu_goods" => { label: "Biens d'un autre pays de l'UE (autoliquidation)", reverse_charge: true, base_grid: "86", due_grid: "55" },
    "outside_eu_services" => { label: "Services hors UE (autoliquidation)", reverse_charge: true, base_grid: "87", due_grid: "56" },
    "no_vat" => { label: "Sans TVA (exonéré ou hors champ)" }
  }.freeze

  BASE_GRIDS = { "81" => "81 · Marchandises", "82" => "82 · Services et biens divers", "83" => "83 · Investissements" }.freeze

  module_function

  def labels = REGIMES.transform_values { |regime| regime[:label] }

  def fetch(regime) = REGIMES.fetch(regime.to_s)

  # Without a VAT amount on the invoice, a supplier from abroad means reverse charge.
  def suggest(country:, vat_amount: nil, goods: false)
    return "domestic" if country.blank? || country == "BE" || vat_amount.to_d.positive?
    return "outside_eu_services" unless Country::EU.include?(country)
    goods ? "intra_eu_goods" : "intra_eu_services"
  end
end
