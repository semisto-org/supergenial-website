# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_24_230200) do
  create_table "audit_events", force: :cascade do |t|
    t.integer "user_id"
    t.string "actor_kind", default: "user", null: false
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.integer "auditable_id"
    t.string "auditable_label"
    t.json "changeset", default: {}, null: false
    t.string "request_id"
    t.datetime "created_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", default: "organisation", null: false
    t.string "vat_number"
    t.text "address"
    t.string "status", default: "actif", null: false
    t.decimal "hourly_rate", precision: 8, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "street"
    t.string "postal_code"
    t.string "city"
    t.string "country", default: "BE", null: false
    t.string "billing_email"
    t.string "peppol_id"
    t.datetime "peppol_checked_at"
    t.boolean "peppol_reachable"
    t.index ["name"], name: "index_clients_on_name", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.integer "commentable_id", null: false
    t.integer "user_id", null: false
    t.text "body", null: false
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "company_profiles", force: :cascade do |t|
    t.string "legal_name", null: false
    t.string "trade_name"
    t.string "vat_number"
    t.string "street"
    t.string "postal_code"
    t.string "city"
    t.string "country", default: "BE", null: false
    t.string "email"
    t.string "phone"
    t.string "website"
    t.string "iban"
    t.string "bic"
    t.integer "payment_terms_days", default: 30, null: false
    t.string "last_external_number"
    t.text "invoice_footer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "client_id", null: false
    t.string "role"
    t.string "email"
    t.string "phone"
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.index ["client_id"], name: "index_contacts_on_client_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "project_id"
    t.integer "fixed_cost_id"
    t.string "label", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.decimal "cost", precision: 10, scale: 2
    t.string "period", default: "annuel", null: false
    t.date "starts_on"
    t.date "next_billing_on"
    t.date "last_billed_on"
    t.string "status", default: "actif", null: false
    t.string "registrar"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "kinds", default: [], null: false
    t.integer "plan_id"
    t.index ["client_id"], name: "index_contracts_on_client_id"
    t.index ["fixed_cost_id"], name: "index_contracts_on_fixed_cost_id"
    t.index ["next_billing_on"], name: "index_contracts_on_next_billing_on"
    t.index ["plan_id"], name: "index_contracts_on_plan_id"
    t.index ["project_id"], name: "index_contracts_on_project_id"
  end

  create_table "expense_categories", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "pcmn_account"
    t.decimal "vat_rate", precision: 5, scale: 2
    t.decimal "vat_deductible_percent", precision: 5, scale: 2, default: "100.0", null: false
    t.decimal "tax_deductible_percent", precision: 5, scale: 2, default: "100.0", null: false
    t.integer "position", default: 0, null: false
    t.datetime "validated_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_expense_categories_on_key", unique: true
  end

  create_table "fixed_costs", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", default: "outils", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "period", default: "mensuel", null: false
    t.decimal "forecast_amount", precision: 10, scale: 2
    t.date "renews_on"
    t.string "action"
    t.string "billing_url"
    t.boolean "active", default: true, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supplier_id"
    t.index ["supplier_id"], name: "index_fixed_costs_on_supplier_id"
  end

  create_table "hourly_rates", force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.date "starts_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["starts_on"], name: "index_hourly_rates_on_starts_on", unique: true
  end

  create_table "invoice_lines", force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.integer "position", default: 0, null: false
    t.string "description", null: false
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.string "unit", default: "unit", null: false
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "vat_rate", precision: 5, scale: 2, default: "21.0", null: false
    t.date "period_start"
    t.date "period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_lines_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "project_id"
    t.string "number"
    t.string "label", null: false
    t.date "issued_on", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "paid_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind", default: "invoice", null: false
    t.string "status", default: "draft", null: false
    t.string "source", default: "admin", null: false
    t.integer "credited_invoice_id"
    t.date "due_on"
    t.string "vat_regime", default: "standard", null: false
    t.decimal "vat_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "structured_reference"
    t.datetime "issued_at"
    t.json "buyer", default: {}, null: false
    t.json "seller", default: {}, null: false
    t.text "ubl_xml"
    t.string "peppol_status"
    t.string "peppol_document_id"
    t.datetime "sent_at"
    t.text "send_error"
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["credited_invoice_id"], name: "index_invoices_on_credited_invoice_id"
    t.index ["issued_on"], name: "index_invoices_on_issued_on"
    t.index ["number"], name: "index_invoices_on_number", unique: true, where: "number IS NOT NULL AND source = 'admin'"
    t.index ["project_id"], name: "index_invoices_on_project_id"
  end

  create_table "packs", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "invoice_id"
    t.string "label", null: false
    t.decimal "hours", precision: 6, scale: 2, null: false
    t.decimal "hourly_rate", precision: 8, scale: 2
    t.date "purchased_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_packs_on_client_id"
    t.index ["invoice_id"], name: "index_packs_on_invoice_id"
  end

  create_table "plan_prices", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "starts_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id", "starts_on"], name: "index_plan_prices_on_plan_id_and_starts_on", unique: true
    t.index ["plan_id"], name: "index_plan_prices_on_plan_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "period", default: "mensuel", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_plans_on_name", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.integer "client_id", null: false
    t.string "name", null: false
    t.string "kind", default: "application", null: false
    t.string "billing_mode", default: "forfait", null: false
    t.decimal "fixed_price", precision: 10, scale: 2
    t.decimal "hourly_rate", precision: 8, scale: 2
    t.string "status", default: "en_cours", null: false
    t.date "started_on"
    t.date "ended_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_projects_on_client_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "vat_number"
    t.string "iban"
    t.string "billing_country", default: "BE", null: false
    t.string "group_country"
    t.integer "expense_category_id"
    t.string "peppol_id"
    t.boolean "require_peppol", default: false, null: false
    t.boolean "active", default: true, null: false
    t.string "website"
    t.text "alternative_note"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_category_id"], name: "index_suppliers_on_expense_category_id"
    t.index ["vat_number"], name: "index_suppliers_on_vat_number"
  end

  create_table "time_entries", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "project_id"
    t.integer "pack_id"
    t.integer "invoice_id"
    t.date "performed_on", null: false
    t.string "description"
    t.decimal "hours", precision: 6, scale: 2, null: false
    t.integer "km"
    t.string "location"
    t.string "status", default: "a_facturer", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_time_entries_on_client_id"
    t.index ["invoice_id"], name: "index_time_entries_on_invoice_id"
    t.index ["pack_id"], name: "index_time_entries_on_pack_id"
    t.index ["project_id"], name: "index_time_entries_on_project_id"
    t.index ["status", "performed_on"], name: "index_time_entries_on_status_and_performed_on"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "admin", null: false
    t.string "name"
    t.text "otp_secret"
    t.datetime "otp_enabled_at"
    t.integer "otp_last_used_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "audit_events", "users", on_delete: :nullify
  add_foreign_key "comments", "users"
  add_foreign_key "contacts", "clients"
  add_foreign_key "contracts", "clients"
  add_foreign_key "contracts", "fixed_costs"
  add_foreign_key "contracts", "plans"
  add_foreign_key "contracts", "projects"
  add_foreign_key "fixed_costs", "suppliers"
  add_foreign_key "invoice_lines", "invoices", on_delete: :cascade
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "invoices", column: "credited_invoice_id"
  add_foreign_key "invoices", "projects"
  add_foreign_key "packs", "clients"
  add_foreign_key "packs", "invoices"
  add_foreign_key "plan_prices", "plans"
  add_foreign_key "projects", "clients"
  add_foreign_key "sessions", "users"
  add_foreign_key "suppliers", "expense_categories"
  add_foreign_key "time_entries", "clients"
  add_foreign_key "time_entries", "invoices"
  add_foreign_key "time_entries", "packs"
  add_foreign_key "time_entries", "projects"
end
