# Plain-hash views of the records returned by tools. Money is rounded to the cent.
module AdminMcp::Serializer
  module_function

  def money(value) = value&.to_d&.round(2)&.to_f

  def client(client, detail: false)
    data = {
      id: client.id, name: client.name, kind: client.kind, status: client.status, vat_number: client.vat_number,
      hourly_rate: money(client.hourly_rate), effective_hourly_rate: money(client.rate),
      primary_contact: client.primary_contact&.then { |contact| contact(contact) }
    }
    return data unless detail

    data.merge(
      street: client.street, postal_code: client.postal_code, city: client.city, country: client.country,
      billing_email: client.billing_email, peppol_id: client.peppol_id, notes: client.notes,
      unbilled_hours: client.unbilled_hours.to_f, unbilled_amount: money(client.unbilled_amount),
      contacts: client.contacts.map { |contact| contact(contact) },
      projects: client.projects.order(started_on: :desc).map { |project| project(project) },
      contracts: client.contracts.includes(plan: :prices).by_due_date.map { |contract| contract(contract) },
      packs: client.packs.includes(:time_entries).map { |pack| pack(pack) },
      recent_invoices: client.invoices.recent.limit(10).map { |invoice| invoice(invoice) }
    )
  end

  def contact(contact)
    contact.slice(:id, :client_id, :first_name, :last_name, :role, :email, :phone, :primary).merge(full_name: contact.full_name)
  end

  def project(project, detail: false)
    data = project.slice(:id, :client_id, :name, :kind, :billing_mode, :status, :started_on, :ended_on)
                  .merge(client_name: project.client.name, fixed_price: money(project.fixed_price),
                         hourly_rate: money(project.hourly_rate), effective_hourly_rate: money(project.rate))
    return data unless detail

    data.merge(notes: project.notes, hours_spent: project.hours_spent.to_f, invoiced: money(project.invoiced),
               recent_time_entries: project.time_entries.recent.limit(20).map { |entry| time_entry(entry) },
               contracts: project.contracts.map { |contract| contract(contract) },
               invoices: project.invoices.recent.map { |invoice| invoice(invoice) })
  end

  def time_entry(entry)
    entry.slice(:id, :client_id, :project_id, :pack_id, :invoice_id, :performed_on, :description, :km, :location, :status)
         .merge(client_name: entry.client.name, project_name: entry.project&.name, hours: entry.hours.to_f,
                rate: money(entry.rate), amount: money(entry.amount))
  end

  def pack(pack)
    pack.slice(:id, :client_id, :invoice_id, :label, :purchased_on)
        .merge(hours: pack.hours.to_f, used_hours: pack.used_hours.to_f, remaining_hours: pack.remaining_hours.to_f,
               hourly_rate: money(pack.hourly_rate))
  end

  def contract(contract, detail: false)
    data = contract.slice(:id, :client_id, :project_id, :plan_id, :fixed_cost_id, :label, :kinds, :period, :status,
                          :starts_on, :next_billing_on, :last_billed_on, :registrar)
                   .merge(client_name: contract.client.name, plan_name: contract.plan&.name,
                          amount: money(contract.amount), current_amount: money(contract.current_amount),
                          negotiated_price: contract.negotiated?, yearly_amount: money(contract.yearly_amount),
                          cost: money(contract.cost), margin_rate: contract.margin_rate&.to_f, due: contract.due?)
    return data unless detail

    next_price = contract.next_plan_price
    data.merge(notes: contract.notes, yearly_margin: money(contract.yearly_margin),
               revenue_over_next_year: money(contract.revenue_over_next_year),
               next_plan_price: next_price && { amount: money(next_price.amount), starts_on: next_price.starts_on })
  end

  def plan(plan)
    plan.slice(:id, :name, :description, :period, :position, :active)
        .merge(current_price: money(plan.current_price),
               prices: plan.prices.map { |price| { id: price.id, amount: money(price.amount), starts_on: price.starts_on } },
               active_contracts: plan.active_contracts.size, yearly_revenue: money(plan.yearly_revenue))
  end

  def fixed_cost(cost)
    cost.slice(:id, :name, :category, :supplier_id, :period, :renews_on, :action, :billing_url, :active, :notes)
        .merge(amount: money(cost.amount), forecast_amount: money(cost.forecast_amount),
               monthly_amount: money(cost.monthly_amount), monthly_forecast: money(cost.monthly_forecast))
  end

  def hourly_rate(rate) = { id: rate.id, amount: money(rate.amount), starts_on: rate.starts_on }

  def invoice(invoice, detail: false)
    data = invoice.slice(:id, :client_id, :project_id, :kind, :status, :source, :number, :label, :issued_on, :due_on, :paid_on,
                         :vat_regime, :credited_invoice_id, :peppol_status, :sent_at)
                  .merge(client_name: invoice.client.name, amount_excl_vat: money(invoice.amount),
                         vat_amount: money(invoice.vat_amount), total_incl_vat: money(invoice.total), paid: invoice.paid?)
    return data unless detail

    data.merge(notes: invoice.notes, structured_reference: invoice.structured_reference, send_error: invoice.send_error,
               lines: invoice.lines.map { |line|
                 line.slice(:id, :position, :description, :unit, :period_start, :period_end)
                     .merge(quantity: line.quantity.to_f, unit_price: money(line.unit_price), vat_rate: line.vat_rate.to_f, net_amount: money(line.net_amount))
               },
               vat_subtotals: invoice.vat_subtotals.map { |row| row.transform_values { |value| money(value) } },
               credit_notes: invoice.credit_notes.map { |note| { id: note.id, number: note.number, status: note.status } })
  end
end
