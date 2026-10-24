class CreateOauthTables < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_clients do |t|
      t.string :uid, null: false
      t.string :name, null: false
      t.json :redirect_uris, null: false, default: []
      t.timestamps
    end
    add_index :oauth_clients, :uid, unique: true

    create_table :oauth_authorization_codes do |t|
      t.references :oauth_client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :code_digest, null: false
      t.string :redirect_uri, null: false
      t.string :code_challenge, null: false
      t.string :resource
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps
    end
    add_index :oauth_authorization_codes, :code_digest, unique: true

    create_table :oauth_tokens do |t|
      t.references :oauth_client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :access_token_digest, null: false
      t.string :refresh_token_digest, null: false
      t.datetime :access_expires_at, null: false
      t.datetime :refresh_expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :oauth_tokens, :access_token_digest, unique: true
    add_index :oauth_tokens, :refresh_token_digest, unique: true
  end
end
