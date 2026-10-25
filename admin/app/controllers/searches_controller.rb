# Backs the ⌘K palette: pages, quick actions and matching records as JSON.
class SearchesController < ApplicationController
  LIMIT = 5

  def show
    @query = params[:q].to_s.strip
    render json: { results: page_results + action_results + record_results }
  end

  private
    def page_results
      pages = [ [ "Tableau de bord", root_path, "dashboard" ] ]
      helpers.navigation.each_value do |links|
        links.each { |label, path, section| pages << [ label, public_send(path), section.to_s ] }
      end
      pages.filter_map do |label, url, section|
        next unless matches?(label)
        shortcut = ApplicationHelper::SHORTCUTS[section]
        { group: "Pages", label:, url:, hint: ("G #{shortcut.upcase}" if shortcut) }
      end
    end

    def action_results
      return [] unless helpers.can_write?

      [ [ "Encoder des heures", new_time_entry_path ], [ "Nouveau client", new_client_path ], [ "Nouveau projet", new_project_path ],
        [ "Nouvelle facture", new_invoice_path ], [ "Nouveau contrat", new_contract_path ] ]
        .select { |label, _| matches?(label) }
        .map { |label, url| { group: "Actions", label:, url: } }
    end

    def record_results
      return Client.order(updated_at: :desc).limit(LIMIT).map { |client| record(client, "Clients récents", client.status_label) } if @query.blank?

      [ *search(Client, :name).map { |client| record(client, "Clients", client.status_label) },
        *search(Project.includes(:client), :name).map { |project| record(project, "Projets", project.client.to_s) },
        *search(Contract.includes(:client), :label).map { |contract| record(contract, "Contrats", contract.client.to_s) },
        *search(Invoice.includes(:client), :number, :label).map { |invoice| record(invoice, "Factures", invoice.client.to_s) },
        *search(Supplier, :name).map { |supplier| record(supplier, "Fournisseurs", nil) } ]
    end

    def search(scope, *columns)
      pattern = "%#{Invoice.sanitize_sql_like(@query)}%"
      conditions = columns.map { |column| scope.arel_table[column].matches(pattern) }.reduce(:or)
      scope.where(conditions).order(updated_at: :desc).limit(LIMIT)
    end

    def record(record, group, hint)
      { group:, label: record.to_s, url: polymorphic_path(record), hint: }
    end

    def matches?(label)
      @query.blank? || I18n.transliterate(label).downcase.include?(I18n.transliterate(@query).downcase)
    end
end
