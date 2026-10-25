class AddInvoicingFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :street, :string
    add_column :clients, :postal_code, :string
    add_column :clients, :city, :string
    add_column :clients, :country, :string, null: false, default: "BE"
    add_column :clients, :billing_email, :string
    add_column :clients, :peppol_id, :string
    add_column :clients, :peppol_checked_at, :datetime
    add_column :clients, :peppol_reachable, :boolean
  end
end
