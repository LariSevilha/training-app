class CreateRepeats < ActiveRecord::Migration[7.2]
  def change
    create_table :repeats do |t|
      t.integer :amount

      t.timestamps
    end
  end
end
