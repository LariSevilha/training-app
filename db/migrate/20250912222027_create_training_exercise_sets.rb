class CreateTrainingExerciseSets < ActiveRecord::Migration[7.2]
    def change
      create_table :training_exercise_sets do |t|
        t.references :training_exercise, null: false, foreign_key: true
        t.integer :series_amount, null: false
        t.integer :repeats_amount, null: false
        t.timestamps
      end
    end
  end