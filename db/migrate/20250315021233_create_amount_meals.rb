class CreateAmountMeals < ActiveRecord::Migration[7.2]
  def change
    create_table :amount_meals do |t|
      t.integer :amount

      t.timestamps
    end
  end
end
