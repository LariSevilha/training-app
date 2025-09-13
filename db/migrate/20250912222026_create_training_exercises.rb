class CreateTrainingExercises < ActiveRecord::Migration[7.2]
    def change
      create_table :training_exercises do |t|
        t.references :training, null: false, foreign_key: true
        t.references :exercise, null: false, foreign_key: true
        t.timestamps
      end
    end
  end