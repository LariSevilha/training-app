class CreateApiKeys < ActiveRecord::Migration[7.0]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :device_id, null: false
      t.string :token, null: false
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :api_keys, [:user_id, :device_id], unique: true
    add_index :api_keys, :token, unique: true
  end
end