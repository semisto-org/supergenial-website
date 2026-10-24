class CreateBankStatements < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_statements do |t|
      t.string :iban, null: false
      t.integer :number, null: false
      t.date :statement_on, null: false
      t.decimal :opening_balance, precision: 12, scale: 2, null: false
      t.decimal :closing_balance, precision: 12, scale: 2, null: false
      t.string :filename
      t.string :digest, null: false
      t.references :user, foreign_key: true
      t.timestamps
    end
    add_index :bank_statements, :digest, unique: true
    add_index :bank_statements, %i[ iban statement_on number ], unique: true

    create_table :bank_transactions do |t|
      t.references :bank_statement, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.date :booked_on, null: false
      t.date :value_on
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :counterparty_name
      t.string :counterparty_iban
      t.text :communication
      t.string :structured_reference
      t.string :transaction_code
      t.string :bank_reference
      t.string :status, null: false, default: "unmatched"
      t.string :category
      t.references :invoice, foreign_key: true
      t.references :purchase_invoice, foreign_key: true
      t.text :notes
      t.timestamps
    end
    add_index :bank_transactions, %i[ bank_statement_id sequence ], unique: true
    add_index :bank_transactions, :status
    add_index :bank_transactions, :booked_on
  end
end
