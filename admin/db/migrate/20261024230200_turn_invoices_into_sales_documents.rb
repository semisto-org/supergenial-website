# Invoices were references to OkiOki documents. They become full sales documents issued by the admin
# (lines, VAT, Peppol); the existing rows stay as issued OkiOki references.
class TurnInvoicesIntoSalesDocuments < ActiveRecord::Migration[8.1]
  def change
    change_table :invoices, bulk: true do |t|
      t.string :kind, null: false, default: "invoice"
      t.string :status, null: false, default: "draft"
      t.string :source, null: false, default: "admin"
      t.references :credited_invoice, foreign_key: { to_table: :invoices }
      t.date :due_on
      t.string :vat_regime, null: false, default: "standard"
      t.decimal :vat_amount, precision: 12, scale: 2, null: false, default: 0
      t.string :structured_reference
      t.datetime :issued_at
      t.json :buyer, null: false, default: {}
      t.json :seller, null: false, default: {}
      t.text :ubl_xml
      t.string :peppol_status
      t.string :peppol_document_id
      t.datetime :sent_at
      t.text :send_error
    end
    add_index :invoices, :number, unique: true, where: "number IS NOT NULL AND source = 'admin'"

    reversible do |direction|
      direction.up { execute "UPDATE invoices SET status = 'issued', source = 'okioki'" }
    end

    create_table :invoice_lines do |t|
      t.references :invoice, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.string :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1
      t.string :unit, null: false, default: "unit"
      t.decimal :unit_price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :vat_rate, precision: 5, scale: 2, null: false, default: 21
      t.date :period_start
      t.date :period_end
      t.timestamps
    end
  end
end
