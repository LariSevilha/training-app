class CreateTrainings < ActiveRecord::Migration[7.2]
  def change
    create_table :trainings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :serie, null: false, foreign_key: true
      t.references :repeat, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :weekday, null: false, default: 0
      t.text :description 
      t.timestamps
    end
  end
end
