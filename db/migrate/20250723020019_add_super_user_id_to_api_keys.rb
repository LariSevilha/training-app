class AddSuperUserIdToApiKeys < ActiveRecord::Migration[7.2]
  def change
    add_column :api_keys, :super_user_id, :bigint
    add_index :api_keys, :super_user_id
    add_foreign_key :api_keys, :super_users, column: :super_user_id
  end
end