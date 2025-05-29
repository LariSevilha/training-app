class CreateWeeklyPdfs < ActiveRecord::Migration[7.2]
  def change
    create_table :weekly_pdfs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :weekday

      t.timestamps
    end
  end
end
