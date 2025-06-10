class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.integer :permission_id  
      t.string :avatar
      t.integer :user_type  
      t.integer :role
      t.string :device_token
      t.string :phone_number, null: false, default: ""
      t.string :plan_duration
      t.string :plan_type 
      t.datetime :registration_date
      t.datetime :expiration_date

      t.timestamps
    end
  end
end
