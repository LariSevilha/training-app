class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.integer :permission_id  
      t.string :avatar
      t.integer :user_type  
      t.integer :role
 

      t.timestamps
    end
  end
end
