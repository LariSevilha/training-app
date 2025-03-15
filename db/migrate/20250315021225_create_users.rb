class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.integer :permission_id
      t.string :email
      t.string :password
      t.string :avatar
      t.references :user_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
