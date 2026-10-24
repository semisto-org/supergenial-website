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
      [ "Frais fixes", :fixed_costs_path, :fixed_costs, "receipt" ],
      [ "Taux horaire", :hourly_rates_path, :hourly_rates, "euro" ]
    ]
  }.freeze

  # Page icons shown above the title, by controller.
  PAGE_ICONS = {
    "dashboard" => "🧭", "clients" => "🤝", "contacts" => "🤝", "projects" => "📁", "time_entries" => "⏱️",
    "packs" => "⏳", "contracts" => "🔁", "invoices" => "🧾", "plans" => "🏷️", "hourly_rates" => "💶",
    "fixed_costs" => "📌"
  }.freeze

  def navigation = NAVIGATION

  def icon(name, **options)
    tag.svg(tag.use(href: "#icon-#{name}"), class: [ "icon", options.delete(:class) ], "aria-hidden": true, **options)
  end

  def nav_link(label, path, section, icon: nil)
    active = controller_name == section.to_s || (section == :clients && controller_name.in?(%w[ contacts packs ]))
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
