class CreateTrainings < ActiveRecord::Migration[7.2]
  def change
    create_table :trainings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :exercise_name, null: false
      t.integer :serie_amount, default: 0
      t.integer :repeat_amount, default: 0
      t.string :video

      t.timestamps
    end
  end
end
