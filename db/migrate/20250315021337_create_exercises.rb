class CreateExercises < ActiveRecord::Migration[7.2]
  def change
    create_table :exercises do |t|
      t.string :name
      t.string :video

      t.timestamps
    end
  end
end
