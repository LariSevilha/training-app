class AddActiveDeviceIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :active_device_id, :string
  end
end
