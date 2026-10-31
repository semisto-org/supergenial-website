class CreateBankConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_connections do |t|
      t.string :aspsp_name, null: false
      t.string :country, null: false, default: "BE"
      t.string :psu_type, null: false, default: "business"
      t.string :status, null: false, default: "pending"
      t.string :state, null: false, index: { unique: true }
      t.string :session_id
      t.datetime :valid_until
      t.json :accounts, null: false, default: []
      t.datetime :last_synced_at
      t.text :last_error
      t.references :user
      t.timestamps
    end

    change_column_null :bank_transactions, :bank_statement_id, true
    change_column_null :bank_transactions, :sequence, true
    add_reference :bank_transactions, :bank_connection
    add_column :bank_transactions, :account_iban, :string
    add_column :bank_transactions, :external_id, :string
    add_index :bank_transactions, %i[ account_iban external_id ], unique: true, where: "external_id IS NOT NULL"
  end
end
