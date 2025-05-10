class CreateMeals < ActiveRecord::Migration[7.2]
  def change
    create_table :meals do |t|
      t.string :meal_type 
      t.integer :weekday, null: false, default: 0

      t.timestamps
    end
  end
end
