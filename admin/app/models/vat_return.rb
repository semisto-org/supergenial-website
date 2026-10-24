# The Belgian periodic VAT return of a quarter, computed from the sales and purchase documents.
# An open quarter takes every document not declared yet and dated up to its last day (a late invoice from
# a closed quarter lands in the next open one, as the law requires); a closed quarter keeps what it declared.
#
# Sales: 00/01/02/03 by rate, 44 intra-EU services, 47 services outside the EU, 54 VAT due,
#        48 and 49 credit notes issued, 64 VAT on them.
# Purchases: 81/82/83 base, 86/87/88 reverse charge, 55/56 self-assessed VAT, 59 deductible VAT,
#            84 and 85 credit notes received, 63 VAT deducted to give back.
class VatReturn
  GRID_LABELS = {
    "00" => "Ventes à 0 %", "01" => "Ventes à 6 %", "02" => "Ventes à 12 %", "03" => "Ventes à 21 %",
    "44" => "Services à des clients de l'UE", "45" => "Cocontractant", "46" => "Livraisons intracommunautaires",
    "47" => "Autres opérations exemptées et hors champ", "48" => "Notes de crédit sur les grilles 44 et 46", "49" => "Autres notes de crédit émises",
    "54" => "TVA due sur les ventes", "55" => "TVA autoliquidée, achats intracommunautaires", "56" => "TVA autoliquidée, cocontractant et hors UE",
    "57" => "TVA sur importations", "59" => "TVA déductible", "61" => "Régularisations en faveur de l'État", "62" => "Régularisations en faveur du déclarant",
    "63" => "TVA à reverser sur les notes de crédit reçues", "64" => "TVA à récupérer sur les notes de crédit",
    "71" => "Solde dû à l'État", "72" => "Solde en faveur du déclarant",
    "81" => "Achats de marchandises", "82" => "Achats de services et biens divers", "83" => "Investissements",
    "84" => "Notes de crédit reçues sur les grilles 86 et 88", "85" => "Autres notes de crédit reçues",
    "86" => "Biens achetés dans l'UE", "87" => "Autres achats en autoliquidation (hors UE)", "88" => "Services achetés dans l'UE"
  }.freeze

  SALES_RATE_GRIDS = { 0 => "00", 6 => "01", 12 => "02", 21 => "03" }.freeze
  DUE_GRIDS = %w[ 54 55 56 57 61 63 ].freeze
  DEDUCTIBLE_GRIDS = %w[ 59 62 64 ].freeze

  Quarter = Data.define(:year, :quarter) do
    def self.containing(date) = new(year: date.year, quarter: (date.month - 1) / 3 + 1)

    def self.parse(param)
      year, quarter = param.to_s.split("-").map(&:to_i)
      new(year:, quarter:) if year.to_i > 2000 && quarter.in?(1..4)
    end

    def starts_on = Date.new(year, quarter * 3 - 2, 1)

    def ends_on = starts_on.end_of_quarter

    def range = starts_on..ends_on

    def previous = self.class.containing(starts_on - 1)

    def next = self.class.containing(ends_on + 1)

    # Return and intra-EU listing are due on the 20th of the month after the quarter.
    def deadline = ends_on + 20

    def label = "T#{quarter} #{year}"

    def to_param = "#{year}-#{quarter}"
  end

  Control = Data.define(:message, :blocking, :documents)

  attr_reader :quarter

  def initialize(quarter)
    @quarter = quarter
  end

  def period = defined?(@period) ? @period : (@period = VatPeriod.find_by(year: quarter.year, quarter: quarter.quarter))

  def closed? = period.present?

  def tracked_since = CompanyProfile.current.vat_tracked_since || Date.new(2000, 1, 1)

  def invoices
    @invoices ||= if closed?
      Invoice.where(vat_period: period).includes(:client, :lines).to_a
    else
      Invoice.counted.where(vat_period_id: nil, issued_on: tracked_since..quarter.ends_on).includes(:client, :lines).to_a
    end
  end

  def purchase_invoices
    @purchase_invoices ||= if closed?
      PurchaseInvoice.where(vat_period: period).includes(:supplier).to_a
    else
      PurchaseInvoice.where(vat_period_id: nil, issued_on: tracked_since..quarter.ends_on).includes(:supplier).to_a
    end
  end

  def grids
    return period.grids.transform_values(&:to_d) if closed?
    @grids ||= begin
      grids = Hash.new { |hash, key| hash[key] = 0.to_d }
      invoices.each { |invoice| add_sale(grids, invoice) }
      purchase_invoices.each { |purchase| add_purchase(grids, purchase) }
      add_balance(grids)
      grids.transform_values { |value| value.round(2) }.reject { |_, value| value.zero? }.sort_by { |grid, _| grid.to_i }.to_h
    end
  end

  def to_pay = grids.fetch("71", 0)

  def to_recover = grids.fetch("72", 0)

  # Intra-EU customers and the services invoiced to them, net of credit notes (listing code S).
  def intracom_listing
    return period.intracom_listing if closed?
    invoices.select(&:intra_eu?).group_by { |invoice| buyer_vat(invoice) }.filter_map do |vat_number, client_invoices|
      next if vat_number.blank?
      { "vat_number" => vat_number, "client" => client_invoices.first.client.name, "code" => "S", "amount" => client_invoices.sum(&:amount).round(2).to_s }
    end.sort_by { |row| row["vat_number"] }
  end

  def controls
    return [] if closed?
    [
      control("Achat(s) encore à vérifier", true, purchase_invoices.select(&:to_review?)),
      control("Client(s) intracommunautaire(s) sans numéro de TVA", true, invoices.select { |invoice| invoice.intra_eu? && buyer_vat(invoice).blank? }),
      control("Achat(s) en autoliquidation sans n° de TVA du fournisseur", false, purchase_invoices.select { |purchase| purchase.reverse_charge? && purchase.supplier&.vat_number.blank? }),
      control("Brouillon(s) daté(s) dans le trimestre, pas encore émis", false, Invoice.draft.where(issued_on: quarter.range).to_a),
      control("Mouvement(s) bancaire(s) du trimestre à rapprocher", false, BankTransaction.unmatched.where(booked_on: quarter.range).to_a)
    ].compact
  end

  def blocking_controls = controls.select(&:blocking)

  # Quarters are closed in order, from the first one tracked in the admin.
  def previous_closed? = quarter.previous.ends_on < tracked_since || VatReturn.new(quarter.previous).closed?

  def closable? = !closed? && quarter.ends_on < Date.current && previous_closed? && blocking_controls.empty?

  def close!(user:)
    raise ArgumentError, "Ce trimestre ne peut pas être clôturé" unless closable?
    VatPeriod.transaction do
      @period = VatPeriod.create!(year: quarter.year, quarter: quarter.quarter, closed_at: Time.current, closed_by: user,
                                  grids: grids.transform_values(&:to_s), intracom_listing:)
      Invoice.where(id: invoices.map(&:id)).update_all(vat_period_id: period.id)
      PurchaseInvoice.where(id: purchase_invoices.map(&:id)).update_all(vat_period_id: period.id)
    end
    @invoices = @purchase_invoices = @grids = nil
    period
  end

  private
    def control(message, blocking, documents) = documents.any? ? Control.new(message:, blocking:, documents:) : nil

    def buyer_vat(invoice) = (invoice.buyer.to_h["vat_number"].presence || invoice.client.vat_number).to_s.upcase.gsub(/[^A-Z0-9]/, "").presence

    def add_sale(grids, invoice)
      base = invoice.amount.to_d.abs
      vat = invoice.vat_amount.to_d.abs
      if invoice.credit_note?
        grids[invoice.intra_eu? ? "48" : "49"] += base
        grids["64"] += vat
      elsif invoice.standard?
        sale_subtotals(invoice).each { |rate, taxable| grids[SALES_RATE_GRIDS.fetch(rate, "03")] += taxable }
        grids["54"] += vat
      else
        grids[invoice.regime[:grid]] += base
      end
    end

    # Admin invoices know their rates line by line; older references only their totals.
    def sale_subtotals(invoice)
      if invoice.lines.any?
        invoice.vat_subtotals.to_h { |subtotal| [ subtotal[:rate].to_i, subtotal[:taxable] ] }
      else
        rate = invoice.amount.to_d.zero? ? 21 : (invoice.vat_amount.to_d / invoice.amount.to_d * 100)
        { SALES_RATE_GRIDS.keys.min_by { |known| (known - rate).abs } => invoice.amount.to_d }
      end
    end

    def add_purchase(grids, purchase)
      base = purchase.amount.to_d
      if purchase.credit_note?
        grids["85"] += base
        grids["84"] += base if purchase.reverse_charge? && purchase.regime[:base_grid] != "87"
        grids["64"] += purchase.self_assessed_vat if purchase.reverse_charge?
        grids["63"] += purchase.deductible_vat
      else
        grids[purchase.base_grid] += base
        if purchase.reverse_charge?
          grids[purchase.regime[:base_grid]] += base
          grids[purchase.regime[:due_grid]] += purchase.self_assessed_vat
        end
        grids["59"] += purchase.deductible_vat
      end
    end

    def add_balance(grids)
      balance = DUE_GRIDS.sum { |grid| grids.fetch(grid, 0) } - DEDUCTIBLE_GRIDS.sum { |grid| grids.fetch(grid, 0) }
      grids[balance.positive? ? "71" : "72"] = balance.abs
    end
end
