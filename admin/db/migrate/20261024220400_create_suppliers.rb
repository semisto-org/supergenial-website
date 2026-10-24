class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :vat_number
      t.string :iban
      t.string :billing_country, null: false, default: "BE"
      t.string :group_country
      t.references :expense_category, foreign_key: true
      t.string :peppol_id
      t.boolean :require_peppol, null: false, default: false
      t.boolean :active, null: false, default: true
      t.string :website
      t.text :alternative_note
      t.text :notes
      t.timestamps
    end
    add_index :suppliers, :vat_number

    add_reference :fixed_costs, :supplier, foreign_key: true
  end
end
