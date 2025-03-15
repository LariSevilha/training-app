class CreateUserTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :user_types do |t|
      t.string :permission

      t.timestamps
    end
  end
end
