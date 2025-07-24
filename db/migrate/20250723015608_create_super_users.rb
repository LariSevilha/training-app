class CreateSuperUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :super_users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index ["email"], name: "index_super_users_on_email", unique: true
    end
  end
end