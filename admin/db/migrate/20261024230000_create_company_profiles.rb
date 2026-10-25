# The seller printed on every invoice (one row). Filled in from the admin, never from the repository.
class CreateCompanyProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :company_profiles do |t|
      t.string :legal_name, null: false
      t.string :trade_name
      t.string :vat_number
      t.string :street
      t.string :postal_code
      t.string :city
      t.string :country, null: false, default: "BE"
      t.string :email
      t.string :phone
      t.string :website
      t.string :iban
      t.string :bic
      t.integer :payment_terms_days, null: false, default: 30
      t.string :last_external_number
      t.text :invoice_footer
      t.timestamps
    end

    reversible do |direction|
      direction.up do
        now = connection.quote(Time.current)
        execute "INSERT INTO company_profiles (legal_name, trade_name, country, payment_terms_days, created_at, updated_at) " \
                "VALUES ('Marco & Vespucci SRL', 'Super Génial', 'BE', 30, #{now}, #{now})"
      end
    end
  end
end
