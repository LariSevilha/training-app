class CreateMeals < ActiveRecord::Migration[7.2]
  def change
    create_table :meals do |t|
      t.integer :meal_type

      t.timestamps
    end
  end
end
