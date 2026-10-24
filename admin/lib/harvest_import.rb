require "net/http"

# Imports the Harvest history through its API v2: clients, invoices (as issued Harvest references, with their
# lines) and, optionally, time entries up to a date (to avoid overlapping hours already in the admin).
# Runtime variables: HARVEST_ACCESS_TOKEN, HARVEST_ACCOUNT_ID. Idempotent through the Harvest ids.
class HarvestImport < HistoryImport
  class Api
    BASE_URL = "https://api.harvestapp.com/v2/"

    def self.configured?(env = ENV) = env["HARVEST_ACCESS_TOKEN"].present? && env["HARVEST_ACCOUNT_ID"].present?

    def initialize(env: ENV)
      @token, @account_id = env.fetch("HARVEST_ACCESS_TOKEN"), env.fetch("HARVEST_ACCOUNT_ID")
    end

    # Every record of a collection, following the pages.
    def each(collection, **params, &block)
      uri = URI.join(BASE_URL, collection)
      uri.query = URI.encode_www_form(params.merge(per_page: 2000))
      while uri
        body = get(uri)
        body.fetch(collection).each(&block)
        uri = body.dig("links", "next").presence&.then { URI(_1) }
      end
    end

    private
      def get(uri)
        request = Net::HTTP::Get.new(uri, "Authorization" => "Bearer #{@token}", "Harvest-Account-Id" => @account_id.to_s,
                                          "User-Agent" => "Admin Super Genial (team@supergenial.be)")
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 60) { |http| http.request(request) }
        raise "Harvest a refusé la demande (HTTP #{response.code}) : #{response.body.to_s.truncate(200)}" unless response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      end
  end

  UNITS = { "Service" => "hour", "Product" => "unit" }.freeze

  def initialize(api: Api.new, time_entries_until: nil, **options)
    super(**options)
    @api, @time_entries_until = api, time_entries_until
  end

  private
    def import
      import_clients
      import_invoices
      import_time_entries if @time_entries_until
    end

    def import_clients
      @api.each("clients") do |data|
        client = Client.find_by(harvest_id: data["id"]) || find_or_create_client(data["name"])
        client.update!(harvest_id: data["id"])
        client.update!(address: data["address"]) if client.address.blank? && data["address"].present?
        @clients ||= {}
        @clients[data["id"]] = client
      end
    end

    def client_for(data)
      (@clients ||= {})[data["id"]] ||= Client.find_by(harvest_id: data["id"]) || find_or_create_client(data["name"])
    end

    def import_invoices
      @api.each("invoices") do |data|
        next skip("Factures Harvest") if data["state"] == "draft"

        tax = data["tax_amount"].to_d + data["tax2_amount"].to_d
        net = data["amount"].to_d - tax
        credit_note = net.negative?
        invoice = Invoice.find_or_initialize_by(source: "harvest", external_id: data["id"].to_s)
        invoice.assign_attributes(
          client: client_for(data["client"]), number: data["number"], status: "issued", kind: credit_note ? "credit_note" : "invoice",
          issued_on: data["issue_date"], due_on: data["due_date"], paid_on: data["paid_date"],
          label: data["subject"].presence || "Facture Harvest #{data['number']}", amount: net, vat_amount: tax.abs, notes: data["notes"].presence
        )
        warn "#{data['number']} : en #{data['currency']}, montants repris tels quels" if data["currency"].present? && data["currency"] != "EUR"
        invoice.lines = Array(data["line_items"]).each_with_index.map do |item, position|
          InvoiceLine.new(position:, description: item["description"].presence || item["kind"].presence || "Ligne", quantity: item["quantity"].to_d.nonzero? || 1,
                          unit: UNITS.fetch(item["kind"], "unit"), unit_price: item["unit_price"].to_d.abs, vat_rate: item["taxed"] ? (data["tax"].to_d.round.to_i.presence_in(VatRegime::RATES) || 21) : 0)
        end
        invoice.save!
        count(invoice, credit_note ? "Notes de crédit Harvest" : "Factures Harvest")
      end
    end

    def import_time_entries
      invoices = Invoice.harvest.where.not(external_id: nil).index_by(&:external_id)
      @api.each("time_entries", to: @time_entries_until.iso8601) do |data|
        next skip("Prestations Harvest") if data["hours"].to_d <= 0

        entry = TimeEntry.find_or_initialize_by(external_id: "harvest:#{data['id']}")
        invoice = data["invoice"] && invoices[data["invoice"]["id"].to_s]
        entry.assign_attributes(
          client: client_for(data["client"]), performed_on: data["spent_date"], hours: data["hours"],
          description: [ data.dig("project", "name"), data.dig("task", "name"), data["notes"] ].compact_blank.uniq.join(" · ").truncate(250),
          # Old hours that were never billed will not be anymore: they count as offered, not as hours to bill.
          status: invoice || data["is_billed"] ? "facture" : "offert", invoice:
        )
        entry.save!
        count(entry, "Prestations Harvest")
      end
    end
end
