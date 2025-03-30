class CreateComidas < ActiveRecord::Migration[7.2]
  def change
    create_table :comidas do |t|
      t.string :name
      t.string :amount
      t.integer :amount_meal_id
      t.references :meal, null: false, foreign_key: true

      t.timestamps
    end
  end
end
