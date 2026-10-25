class CreatePurchaseInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_invoices do |t|
      t.references :supplier, foreign_key: true
      t.references :expense_category, foreign_key: true
      t.references :fixed_cost, foreign_key: true
      t.string :kind, null: false, default: "invoice"
      t.string :status, null: false, default: "to_review"
      t.string :source, null: false, default: "manual"
      t.string :external_id
      t.string :number
      t.date :issued_on
      t.date :due_on
      t.date :paid_on
      t.string :currency, null: false, default: "EUR"
      t.decimal :exchange_rate, precision: 12, scale: 6, null: false, default: 1
      t.decimal :original_amount, precision: 10, scale: 2
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :vat_amount, precision: 10, scale: 2, null: false, default: 0
      t.string :vat_regime, null: false, default: "domestic"
      t.decimal :vat_rate, precision: 5, scale: 2, null: false, default: 21
      t.string :base_grid, null: false, default: "82"
      t.decimal :vat_deductible_percent, precision: 5, scale: 2, null: false, default: 100
      t.string :seller_name
      t.string :seller_vat_number
      t.string :seller_country
      t.string :sender_email
      t.string :email_subject
      t.text :ubl_xml
      t.json :extraction
      t.string :extraction_status
      t.text :extraction_error
      t.datetime :booked_at
      t.text :notes
      t.timestamps
    end
    add_index :purchase_invoices, %i[ source external_id ], unique: true, where: "external_id IS NOT NULL"
    add_index :purchase_invoices, :status
    add_index :purchase_invoices, :issued_on
  end
end
