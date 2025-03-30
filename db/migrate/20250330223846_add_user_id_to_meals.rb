class AddUserIdToMeals < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:meals, :user_id)
      add_reference :meals, :user, null: false, foreign_key: true
    end
  end
end
