class AddRoleAndTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "admin"
    add_column :users, :name, :string
    add_column :users, :otp_secret, :text
    add_column :users, :otp_enabled_at, :datetime
    add_column :users, :otp_last_used_at, :integer
  end
end
