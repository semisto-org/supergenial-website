class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :actor_kind, null: false, default: "user"
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.integer :auditable_id
      t.string :auditable_label
      t.json :changeset, null: false, default: {}
      t.string :request_id
      t.datetime :created_at, null: false
    end
    add_index :audit_events, %i[ auditable_type auditable_id ]
    add_index :audit_events, :created_at
  end
end
