class AddMasterUserIdToApiKeys < ActiveRecord::Migration[7.2]
  def change
    add_column :api_keys, :master_user_id, :bigint
    add_index :api_keys, :master_user_id
    add_foreign_key :api_keys, :master_users, column: :master_user_id
    change_column_null :api_keys, :user_id, true
  end
end