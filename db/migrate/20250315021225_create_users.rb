class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.integer :permission_id  
      t.string :avatar
      t.integer :user_type  
      t.integer :role
      t.string :device_token
      t.boolean :blocked, default: false

      t.timestamps
    end
  end
end
