class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.datetime :resolved_at
      t.timestamps
    end
  end
end
