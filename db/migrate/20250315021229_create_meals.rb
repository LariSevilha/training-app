class CreateMeals < ActiveRecord::Migration[7.2]
  def change
    create_table :meals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :meal_type, null: false

      t.timestamps
    end
  end
end