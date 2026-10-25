module ApplicationHelper
  def eur(amount, precision: 2)
    number_to_currency(amount || 0, unit: "€", format: "%n %u", separator: ",", delimiter: " ", precision:)
  end

  def hours(value)
    "#{number_with_precision(value || 0, precision: 2, strip_insignificant_zeros: true, separator: ",")} h"
  end

  def percent(value)
    value.nil? ? "–" : "#{number_with_precision(value, precision: 1, strip_insignificant_zeros: true, separator: ",")} %"
  end

  def date(value) = value ? l(value) : "–"

  BADGE_TONES = {
    "a_facturer" => "warn", "facture" => "ok", "au_pack" => "info", "offert" => "muted",
    "actif" => "ok", "prospect" => "info", "ancien" => "muted", "suspendu" => "warn", "termine" => "muted",
    "devis" => "info", "en_cours" => "ok", "maintenance" => "warn",
    "en_attente" => "warn", "non_signe" => "muted", "abandonne" => "muted"
  }.freeze

  def badge(label, value = nil)
    tag.span(label, class: "badge badge--#{BADGE_TONES.fetch(value.to_s, 'muted')}")
  end

  # Links only to http(s) addresses, never to javascript: or data: URLs.
  def external_link(url, label = url)
    uri = URI.parse(url.to_s)
    link_to(label, uri.to_s, target: "_blank", rel: "noopener") if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end

  def invoice_delivery_badge(invoice)
    case invoice.peppol_status
    when "peppol" then badge("Peppol", "actif")
    when "email" then badge("e-mail", "en_cours")
    when "pending" then badge("en cours", "en_attente")
    else badge("refusé", "suspendu") if invoice.send_error.present?
    end
  end

  # Sidebar sections: label, route helper, controller name, icon.
  NAVIGATION = {
    "Travail" => [
      [ "Clients", :clients_path, :clients, "users" ],
      [ "Projets", :projects_path, :projects, "folder" ],
      [ "Heures", :time_entries_path, :time_entries, "clock" ]
    ],
    "Facturation" => [
      [ "Contrats", :contracts_path, :contracts, "repeat" ],
      [ "Factures", :invoices_path, :invoices, "file" ],
      [ "Abonnements", :plans_path, :plans, "tag" ]
    ],
    "Charges" => [
      [ "Achats", :purchase_invoices_path, :purchase_invoices, "inbox" ],
      [ "Frais fixes", :fixed_costs_path, :fixed_costs, "receipt" ],
      [ "Fournisseurs", :suppliers_path, :suppliers, "truck" ],
      [ "Taux horaire", :hourly_rates_path, :hourly_rates, "euro" ]
    ],
    "Comptabilité" => [
      [ "Banque", :bank_transactions_path, :bank_transactions, "bank" ],
      [ "TVA", :vat_returns_path, :vat_returns, "percent" ],
      [ "Pilotage", :tax_projection_path, :tax_projections, "gauge" ]
    ],
    "Réglages" => [
      [ "Société", :company_profile_path, :company_profiles, "building" ],
      [ "Journal", :audit_events_path, :audit_events, "history" ],
      [ "Comptes", :users_path, :users, "key", :admin ]
    ]
  }.freeze

  # Page icons shown above the title, by controller.
  PAGE_ICONS = {
    "dashboard" => "🧭", "clients" => "🤝", "contacts" => "🤝", "projects" => "📁", "time_entries" => "⏱️",
    "packs" => "⏳", "contracts" => "🔁", "invoices" => "🧾", "plans" => "🏷️", "hourly_rates" => "💶",
    "fixed_costs" => "📌", "suppliers" => "🚚", "audit_events" => "📜", "users" => "🔑",
    "purchase_invoices" => "📥", "bank_transactions" => "🏦", "vat_returns" => "🧮", "tax_projections" => "📈", "company_profiles" => "🏢", "dependences" => "🌍", "import_runs" => "📦", "bank_statements" => "🏦", "tax_parameters" => "📈", "expense_categories" => "📥", "two_factor_setups" => "🔐", "two_factors" => "🔐"
  }.freeze

  # Sidebar links the current user may see; a fifth element restricts a link to admins.
  def navigation
    NAVIGATION.transform_values do |links|
      links.select { |link| link[4] != :admin || Current.user&.admin? }
    end
  end

  def icon(name, **options)
    tag.svg(tag.use(href: "#icon-#{name}"), class: [ "icon", options.delete(:class) ], "aria-hidden": true, **options)
  end

  # Controllers without their own sidebar entry, highlighted under a parent section.
  NESTED_SECTIONS = {
    "contacts" => "clients", "packs" => "clients", "plan_prices" => "plans", "bank_statements" => "bank_transactions",
    "tax_parameters" => "tax_projections", "expense_categories" => "purchase_invoices", "dependences" => "purchase_invoices", "import_runs" => "invoices"
  }.freeze

  def nav_link(label, path, section, icon: nil)
    active = NESTED_SECTIONS.fetch(controller_name, controller_name) == section.to_s
    link_to path, class: "nav-item", "aria-current": ("page" if active) do
      safe_join([ (icon(icon) if icon), tag.span(label) ].compact)
    end
  end

  def page_header(title, &actions)
    content_for(:title, title)
    page_icon = PAGE_ICONS[controller_name]
    tag.header(class: "page-header") do
      safe_join([
        (tag.div(page_icon, class: "page-header__icon", "aria-hidden": true) if page_icon),
        tag.div(class: "page-header__row") do
          safe_join([ tag.h1(title), (tag.div(capture(&actions), class: "actions") if actions) ].compact)
        end
      ].compact)
    end
  end
end
