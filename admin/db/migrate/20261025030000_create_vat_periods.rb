class CreateVatPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :vat_periods do |t|
      t.integer :year, null: false
      t.integer :quarter, null: false
      t.datetime :closed_at, null: false
      t.references :closed_by, foreign_key: { to_table: :users }
      t.json :grids, null: false, default: {}
      t.json :intracom_listing, null: false, default: []
      t.text :notes
      t.timestamps
    end
    add_index :vat_periods, %i[ year quarter ], unique: true

    add_reference :invoices, :vat_period, foreign_key: true
    add_reference :purchase_invoices, :vat_period, foreign_key: true
    # Documents dated before this day were declared outside the admin (e.g. by the previous accountant).
    add_column :company_profiles, :vat_tracked_since, :date
    up_only { execute "UPDATE company_profiles SET vat_tracked_since = '2026-10-01'" }
  end
end
