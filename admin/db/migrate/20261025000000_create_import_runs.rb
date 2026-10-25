class CreateImportRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :import_runs do |t|
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.boolean :dry_run, null: false, default: false
      t.string :filename
      t.json :options, null: false, default: {}
      t.text :report
      t.text :error
      t.references :user, foreign_key: { on_delete: :nullify }
      t.datetime :finished_at
      t.timestamps
    end

    add_column :invoices, :external_id, :string
    add_index :invoices, %i[ source external_id ], unique: true, where: "external_id IS NOT NULL"
    add_column :clients, :harvest_id, :integer
    add_index :clients, :harvest_id, unique: true, where: "harvest_id IS NOT NULL"
    add_column :time_entries, :external_id, :string
    add_index :time_entries, :external_id, unique: true, where: "external_id IS NOT NULL"
  end
end
