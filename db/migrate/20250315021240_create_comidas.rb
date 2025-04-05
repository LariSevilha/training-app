class CreateComidas < ActiveRecord::Migration[7.2]
  def change
    create_table :comidas do |t|
      t.references :meal, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :amount, default: 0

      t.timestamps
    end
  end
end