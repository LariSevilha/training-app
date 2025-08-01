class AddMasterUserToDashboardSettings < ActiveRecord::Migration[7.2]
  def change
    add_reference :dashboard_settings, :master_user, null: false, foreign_key: true
  end
end
