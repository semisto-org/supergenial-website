# MCP server exposing the whole admin to Claude. One folder per domain under app/mcp/admin_mcp/;
# a new domain (accounting…) adds its folder and its tools to DOMAINS.
module AdminMcp
  VERSION = "1.0.0"

  INSTRUCTIONS = <<~TEXT
    Admin of Super Génial (Marco & Vespucci SRL), a Belgian web studio: clients and their contacts, projects,
    time entries (billed by the hour, from prepaid packs, or offered), recurring contracts (maintenance plans,
    hosting, domain names, re-invoicing), subscription plans with dated prices, fixed costs and invoices.
    Sales invoices are made in the admin: a draft (lines, VAT regime) is issued (legal number, then immutable),
    sent over Peppol via Recommand, and corrected only by credit notes. Older documents come from OkiOki and Harvest.
    Stored values (statuses, kinds, periods) are French codes such as "a_facturer" or "mensuel": use the enums
    given in each tool schema. Amounts are in euros, excluding VAT unless named otherwise. Dates are ISO 8601 (YYYY-MM-DD).
    Start with search_clients or get_dashboard. Before deleting anything, show the user what will be deleted
    and ask for confirmation. Every change is recorded in the admin's audit log.
  TEXT

  DOMAINS = {
    overview: [ Overview::GetDashboard ],
    clients: [ Clients::SearchClients, Clients::GetClient, Clients::SaveClient, Clients::DeleteClient ],
    contacts: [ Contacts::SaveContact, Contacts::DeleteContact ],
    projects: [ Projects::ListProjects, Projects::GetProject, Projects::SaveProject, Projects::DeleteProject ],
    hourly_rates: [ HourlyRates::ListHourlyRates, HourlyRates::AddHourlyRate, HourlyRates::DeleteHourlyRate ],
    time_entries: [ TimeEntries::ListTimeEntries, TimeEntries::SaveTimeEntry, TimeEntries::DeleteTimeEntry, TimeEntries::BillTimeEntries ],
    packs: [ Packs::ListPacks, Packs::SavePack, Packs::DeletePack ],
    contracts: [ Contracts::ListContracts, Contracts::GetContract, Contracts::SaveContract, Contracts::DeleteContract, Contracts::BillContract ],
    plans: [ Plans::ListPlans, Plans::SavePlan, Plans::DeletePlan, Plans::AddPlanPrice, Plans::DeletePlanPrice ],
    fixed_costs: [ FixedCosts::ListFixedCosts, FixedCosts::SaveFixedCost, FixedCosts::DeleteFixedCost ],
    invoices: [ Invoices::ListInvoices, Invoices::GetInvoice, Invoices::SaveInvoice, Invoices::IssueInvoice,
                Invoices::SendInvoice, Invoices::CreateCreditNote, Invoices::DeleteInvoice ]
  }.freeze

  def self.tools = DOMAINS.values.flatten

  # Users without write access (the accountant) only see read-only tools.
  def self.tools_for(user) = Tool.can_write?(user) ? tools : tools.reject(&:write?)

  def self.server(user:)
    MCP::Server.new(
      name: "supergenial-admin", title: "Super Génial admin", version: VERSION,
      instructions: INSTRUCTIONS, tools: tools_for(user), server_context: { user: }
    )
  end
end
