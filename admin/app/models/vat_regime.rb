# How VAT applies to a sales document. Decides the Peppol VAT category, the legal mention and the
# grid of the Belgian VAT return the turnover lands in.
module VatRegime
  REGIMES = {
    "standard" => { label: "TVA belge", category: "S" },
    "intra_eu" => { label: "Autoliquidation intracommunautaire", category: "AE", vatex: "VATEX-EU-AE", grid: "44",
                    mention: "Autoliquidation : TVA due par le preneur (article 196 de la directive 2006/112/CE, article 21, § 2 du Code de la TVA)." },
    "outside_eu" => { label: "Client hors Union européenne", category: "O", vatex: "VATEX-EU-O", grid: "47",
                      mention: "Prestation de services hors du champ de la TVA belge (article 21, § 2 du Code de la TVA)." }
  }.freeze

  RATES = [ 21, 12, 6, 0 ].freeze

  module_function

  def labels = REGIMES.transform_values { |regime| regime[:label] }

  def fetch(regime) = REGIMES.fetch(regime.to_s)

  # Business clients in another EU country pay the VAT themselves; outside the EU, Belgian VAT does not apply.
  def suggest(client)
    return "standard" if client.country.blank? || client.country == "BE"
    return "outside_eu" unless Country::EU.include?(client.country)
    client.vat_number.present? ? "intra_eu" : "standard"
  end
end
