class CreateTrainingPhotos < ActiveRecord::Migration[7.2]
  def change
    create_table :training_photos do |t|
      t.references :training, null: false, foreign_key: true
      t.string :image_url

      t.timestamps
    end
  end
end
