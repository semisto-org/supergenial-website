# Countries used for suppliers, grouped into the zones followed on the dashboard (Belgium, EU, US, other).
module Country
  EU = %w[ AT BE BG CY CZ DE DK EE ES FI FR GR HR HU IE IT LT LU LV MT NL PL PT RO SE SI SK ].freeze

  NAMES = {
    "BE" => "Belgique", "FR" => "France", "NL" => "Pays-Bas", "LU" => "Luxembourg", "DE" => "Allemagne",
    "IE" => "Irlande", "ES" => "Espagne", "IT" => "Italie", "PT" => "Portugal", "AT" => "Autriche",
    "DK" => "Danemark", "SE" => "Suède", "FI" => "Finlande", "PL" => "Pologne", "CZ" => "Tchéquie",
    "EE" => "Estonie", "LT" => "Lituanie", "LV" => "Lettonie", "SI" => "Slovénie", "SK" => "Slovaquie",
    "HR" => "Croatie", "HU" => "Hongrie", "RO" => "Roumanie", "BG" => "Bulgarie", "GR" => "Grèce",
    "CY" => "Chypre", "MT" => "Malte", "CH" => "Suisse", "GB" => "Royaume-Uni", "NO" => "Norvège",
    "IS" => "Islande", "US" => "États-Unis", "CA" => "Canada", "CN" => "Chine", "JP" => "Japon",
    "IL" => "Israël", "IN" => "Inde", "AU" => "Australie", "SG" => "Singapour"
  }.freeze

  ZONES = { "be" => "Belgique", "eu" => "Union européenne", "us" => "États-Unis", "other" => "Autres pays" }.freeze

  module_function

  def name(code) = NAMES.fetch(code.to_s, code.to_s)

  def zone(code)
    case code.to_s
    when "BE" then "be"
    when "US" then "us"
    when *EU then "eu"
    else "other"
    end
  end

  def options = NAMES.sort_by { |_, name| [ name == "Belgique" ? 0 : 1, I18n.transliterate(name) ] }.map { |code, name| [ name, code ] }
end
