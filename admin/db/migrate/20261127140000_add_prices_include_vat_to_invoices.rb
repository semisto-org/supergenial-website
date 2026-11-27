class AddPricesIncludeVatToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :prices_include_vat, :boolean, default: false, null: false
  end
end
