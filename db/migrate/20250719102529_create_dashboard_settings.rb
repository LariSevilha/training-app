class CreateDashboardSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :dashboard_settings do |t|
      t.string :primary_color, null: false
      t.string :secondary_color, null: false
      t.string :tertiary_color, null: false
      t.string :app_name, null: false
      t.timestamps
    end
  end
end