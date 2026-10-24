require "test_helper"

class AdminFlowTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "requires authentication" do
    sign_out
    get root_path
    assert_redirected_to new_session_path
  end

  test "every page renders" do
    [ root_path, clients_path, client_path(clients(:dici)), client_path(clients(:silvea)), new_client_path, new_client_contact_path(clients(:dici)),
      projects_path, project_path(projects(:platform)), new_project_path, time_entries_path, new_time_entry_path,
      edit_time_entry_path(time_entries(:visio)), pack_path(packs(:silvea_10h)), new_pack_path, contracts_path,
      contract_path(contracts(:hosting)), new_contract_path, fixed_costs_path, new_fixed_cost_path,
      edit_fixed_cost_path(fixed_costs(:anthropic)), invoices_path(year: 2026), new_invoice_path,
      plans_path, plan_path(plans(:evolution)), new_plan_path, edit_plan_path(plans(:evolution)), new_contract_path(plan_id: plans(:essentiel).id),
      contract_path(contracts(:maintenance)), hourly_rates_path, edit_client_path(clients(:silvea)) ].each do |path|
      get path
      assert_response :success, path
    end
  end

  test "create a client with validation errors" do
    post clients_path, params: { client: { name: "" } }
    assert_response :unprocessable_entity
    post clients_path, params: { client: { name: "Upcyclinarium", kind: "organisation", status: "actif" } }
    assert_redirected_to client_path(Client.find_by!(name: "Upcyclinarium"))
  end

  test "quick time entry" do
    assert_difference -> { clients(:dici).time_entries.count } do
      post time_entries_path, params: { time_entry: { client_id: clients(:dici).id, performed_on: "2026-10-24", hours: "1.5", description: "Visio" } }
    end
    assert_redirected_to time_entries_path
  end

  test "bill selected time entries into one draft invoice" do
    entries = [ time_entries(:visio), time_entries(:dashboard) ]
    post bill_time_entries_path, params: { ids: entries.map(&:id) }

    invoice = Invoice.last
    assert_redirected_to invoice_path(invoice)
    assert invoice.draft?
    assert_equal 300, invoice.amount
    assert_equal 2, invoice.lines.size
    assert entries.all? { |entry| entry.reload.facture? && entry.invoice == invoice }
  end

  test "billing refuses entries from several clients" do
    other = clients(:silvea).time_entries.create!(performed_on: Date.current, hours: 1)
    assert_no_difference -> { Invoice.count } do
      post bill_time_entries_path, params: { ids: [ time_entries(:visio).id, other.id ] }
    end
    assert_redirected_to time_entries_path
    assert time_entries(:visio).reload.a_facturer?
  end

  test "create a contract with several kinds and filter by kind" do
    post contracts_path, params: { contract: { client_id: clients(:dici).id, kinds: [ "", "hebergement", "maintenance" ],
                                               label: "Site Dici", amount: 50, period: "mensuel", status: "actif" } }
    contract = Contract.last
    assert_redirected_to contract_path(contract)
    assert_equal %w[ maintenance hebergement ], contract.kinds

    get contracts_path(kind: "maintenance")
    assert_select "td", text: /Maintenance \+ Hébergement/
    assert_select "a", text: "Hébergement Rewards Manager", count: 0
  end

  test "bill a contract" do
    assert_difference -> { Invoice.count } do
      post bill_contract_path(contracts(:hosting)), params: { number: "2026-051" }
    end
    assert_equal Date.new(2027, 10, 1), contracts(:hosting).reload.next_billing_on
  end

  test "create a plan and schedule a new price" do
    post plans_path, params: { plan: { name: "Croissance", period: "mensuel", active: "1", prices_attributes: [ { amount: "1200", starts_on: "2026-11-01" } ] } }
    plan = Plan.find_by!(name: "Croissance")
    assert_redirected_to plan_path(plan)

    post plan_prices_path(plan), params: { plan_price: { amount: "1300", starts_on: "2027-01-01" } }
    assert_redirected_to plan_path(plan)
    assert_equal [ 1200, 1300 ], plan.prices.reload.map(&:amount)

    delete plan_price_path(plan, plan.prices.last)
    delete plan_price_path(plan, plan.prices.first)
    assert_equal 1, plan.prices.reload.size, "une formule garde au moins un prix"
  end

  test "the standard hourly rate applies at the date of the entry" do
    client = clients(:silvea)
    assert_nil client.hourly_rate
    before = client.time_entries.create!(performed_on: "2026-12-31", hours: 1)
    after = client.time_entries.create!(performed_on: "2027-01-01", hours: 1)
    assert_equal [ 80, 90 ], [ before.rate, after.rate ]
    assert_equal 80, clients(:dici).time_entries.create!(performed_on: "2027-02-01", hours: 1).rate, "un taux propre au client prime"

    post hourly_rates_path, params: { hourly_rate: { amount: "100", starts_on: "2027-06-01" } }
    assert_redirected_to hourly_rates_path
    Current.reset # la requête a sa propre mise en cache des taux, pas celle du test
    assert_equal 100, HourlyRate.on(Date.new(2027, 6, 1))

    HourlyRate.where.not(starts_on: "2026-01-01").find_each { |rate| delete hourly_rate_path(rate) }
    delete hourly_rate_path(hourly_rates(:standard_2026))
    assert_equal 1, HourlyRate.count, "il reste au moins un taux"
  end

  test "link a contract to a plan" do
    post contracts_path, params: { contract: { client_id: clients(:dici).id, kinds: [ "maintenance" ], plan_id: plans(:essentiel).id,
                                               label: "Maintenance Dici", amount: "", status: "actif" } }
    contract = Contract.last
    assert_redirected_to contract_path(contract)
    assert_equal 390, contract.current_amount
  end

  test "delete a client without invoices, with everything it owns" do
    client = clients(:dici)
    assert_difference -> { Client.count } => -1, -> { TimeEntry.count } => -2, -> { Project.count } => -client.projects.count do
      delete client_path(client)
    end
    assert_redirected_to clients_path
  end

  test "a client with invoices cannot be deleted" do
    assert_no_difference -> { Client.count } do
      delete client_path(clients(:silvea))
    end
    assert_redirected_to client_path(clients(:silvea))
    assert_match "1 facture", flash[:alert]
    assert Pack.exists?(packs(:silvea_10h).id), "rien n'est supprimé à moitié"
  end

  test "deleting an invoice puts its hours back to bill" do
    entries = [ time_entries(:visio), time_entries(:dashboard) ]
    post bill_time_entries_path, params: { ids: entries.map(&:id) }
    delete invoice_path(Invoice.last)
    assert entries.all? { |entry| entry.reload.a_facturer? && entry.invoice.nil? }
  end

  test "deleting a pack puts its hours back to bill" do
    delete pack_path(packs(:silvea_10h))
    assert_redirected_to client_path(clients(:silvea))
    entry = time_entries(:seo).reload
    assert entry.a_facturer?
    assert_nil entry.pack
  end

  test "delete the other records" do
    { client_contact_path(clients(:dici), contacts(:ethan)) => Contact, project_path(projects(:platform)) => Project,
      contract_path(contracts(:hosting)) => Contract, fixed_cost_path(fixed_costs(:anthropic)) => FixedCost,
      time_entry_path(time_entries(:visio)) => TimeEntry }.each do |path, model|
      assert_difference -> { model.count }, -1, path do
        delete path
      end
    end
  end
end
