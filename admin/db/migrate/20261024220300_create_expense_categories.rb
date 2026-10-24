# Expense categories with a proposed Belgian chart of accounts (PCMN) mapping.
# The accountant validates each line; until then validated_at stays empty.
class CreateExpenseCategories < ActiveRecord::Migration[8.1]
  PROPOSED = [
    # key, name, PCMN account, VAT rate, VAT deductible %, tax deductible %
    [ "hosting", "Hébergement, serveurs et noms de domaine", "612200", 21, 100, 100 ],
    [ "software", "Logiciels et abonnements", "612300", 21, 100, 100 ],
    [ "ai", "Services d'IA", "612300", 21, 100, 100 ],
    [ "telecom", "Téléphone et internet", "612400", 21, 100, 100 ],
    [ "subcontracting", "Sous-traitance", "604000", 21, 100, 100 ],
    [ "fees", "Honoraires (comptable, avocat…)", "613200", 21, 100, 100 ],
    [ "training", "Formation et documentation", "613800", 21, 100, 100 ],
    [ "small_equipment", "Petit matériel informatique (< 1 000 €)", "611300", 21, 100, 100 ],
    [ "office", "Fournitures de bureau", "612100", 21, 100, 100 ],
    [ "advertising", "Publicité et marketing", "614000", 21, 100, 100 ],
    [ "travel", "Déplacements (train, transports)", "613600", 6, 100, 100 ],
    [ "restaurant", "Restaurant et réception", "614300", 12, 0, 69 ],
    [ "gifts", "Cadeaux d'affaires", "614400", 21, 0, 50 ],
    [ "insurance", "Assurances", "613400", 0, 0, 100 ],
    [ "bank_fees", "Frais bancaires", "657000", 0, 0, 100 ],
    [ "memberships", "Cotisations professionnelles", "613500", 0, 0, 100 ],
    [ "taxes", "Taxes et impôts déductibles", "640000", 0, 0, 100 ],
    [ "other", "Autre", "613900", 21, 100, 100 ]
  ].freeze

  def change
    create_table :expense_categories do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :pcmn_account
      t.decimal :vat_rate, precision: 5, scale: 2
      t.decimal :vat_deductible_percent, precision: 5, scale: 2, null: false, default: 100
      t.decimal :tax_deductible_percent, precision: 5, scale: 2, null: false, default: 100
      t.integer :position, null: false, default: 0
      t.datetime :validated_at
      t.text :notes
      t.timestamps
    end

    reversible do |direction|
      direction.up do
        now = Time.current
        rows = PROPOSED.each_with_index.map do |(key, name, account, vat, vat_deductible, tax_deductible), index|
          { key:, name:, pcmn_account: account, vat_rate: vat, vat_deductible_percent: vat_deductible,
            tax_deductible_percent: tax_deductible, position: index, created_at: now, updated_at: now }
        end
        execute <<~SQL
          INSERT INTO expense_categories (key, name, pcmn_account, vat_rate, vat_deductible_percent, tax_deductible_percent, position, created_at, updated_at)
          VALUES #{rows.map { |row| "(#{row.values.map { |value| connection.quote(value) }.join(', ')})" }.join(', ')}
        SQL
      end
    end
  end
end
