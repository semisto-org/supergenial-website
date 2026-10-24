class CreateTaxParameters < ActiveRecord::Migration[8.1]
  # Starting values for income year 2026, to be checked with the accountant: none of them is marked verified.
  PARAMETERS = [
    [ "isoc_standard_rate", 25, "Taux normal de l'impôt des sociétés (%)", "CIR 92, art. 215" ],
    [ "isoc_reduced_rate", 20, "Taux réduit PME (%)", "CIR 92, art. 215, al. 2" ],
    [ "isoc_reduced_ceiling", 100_000, "Bénéfice imposé au taux réduit (€)", "CIR 92, art. 215, al. 2" ],
    [ "director_min_remuneration", 45_000, "Rémunération minimale du dirigeant pour le taux réduit (€), sauf si elle atteint le bénéfice", "CIR 92, art. 215, al. 3, 4°" ],
    [ "advance_payment_surcharge_rate", 9, "Majoration pour versements anticipés insuffisants (%)", "SPF Finances, taux de l'exercice" ],
    [ "social_contribution_rate", 20.5, "Cotisations sociales d'indépendant (%), première tranche", "Arrêté royal n° 38, art. 12" ],
    [ "social_contribution_ceiling", 72_810, "Plafond de la première tranche (€)", "INASTI, montant indexé" ],
    [ "plci_rate", 8.17, "PLCI : cotisation maximale (% du revenu de référence)", "Loi-programme du 24/12/2002, art. 44" ],
    [ "plci_ceiling", 3_915, "PLCI : plafond annuel (€)", "INASTI, montant indexé" ]
  ].freeze

  def change
    create_table :tax_parameters do |t|
      t.string :key, null: false
      t.decimal :value, precision: 12, scale: 4, null: false
      t.date :valid_from, null: false
      t.string :label, null: false
      t.string :source
      t.datetime :verified_at
      t.text :notes
      t.timestamps
    end
    add_index :tax_parameters, %i[ key valid_from ], unique: true

    create_table :fiscal_plans do |t|
      t.integer :year, null: false
      t.decimal :monthly_remuneration, precision: 10, scale: 2, null: false, default: 0
      t.decimal :year_end_remuneration, precision: 10, scale: 2, null: false, default: 0
      t.decimal :plci_amount, precision: 10, scale: 2, null: false, default: 0
      t.text :notes
      t.timestamps
    end
    add_index :fiscal_plans, :year, unique: true

    reversible do |direction|
      direction.up do
        now = Time.current.to_fs(:db)
        PARAMETERS.each do |key, value, label, source|
          execute "INSERT INTO tax_parameters (key, value, valid_from, label, source, created_at, updated_at) " \
                  "VALUES (#{quote(key)}, #{value}, '2026-01-01', #{quote(label)}, #{quote(source)}, '#{now}', '#{now}')"
        end
      end
    end
  end
end
