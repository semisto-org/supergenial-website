# Le taux horaire standard codé en dur (80 €/h) devient un historique de taux datés.
# Il vaut depuis la plus ancienne prestation encodée, pour que les heures passées gardent leur montant.
class CreateHourlyRates < ActiveRecord::Migration[8.1]
  def up
    create_table :hourly_rates do |t|
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.date :starts_on, null: false
      t.timestamps
      t.index :starts_on, unique: true
    end

    since = [ select_value("SELECT MIN(performed_on) FROM time_entries")&.to_date, Date.new(2026, 1, 1) ].compact.min
    execute "INSERT INTO hourly_rates (amount, starts_on, created_at, updated_at)
             VALUES (80, #{quote(since)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
  end

  def down
    drop_table :hourly_rates
  end
end
