class RemoveNotNullConstraintFromMasterUserIdInDashboardSettings < ActiveRecord::Migration[7.2]
    def change
      change_column_null :dashboard_settings, :master_user_id, true
    end
  end