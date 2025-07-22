class CreateMasterUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :master_users do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :phone_number, null: false
      t.string :password_digest, null: false
      t.string :cpf, null: false, index: { unique: true }
      t.string :cref, null: false
      t.timestamps
    end
  end
end