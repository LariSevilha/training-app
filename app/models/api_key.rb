class ApiKey < ApplicationRecord
  belongs_to :user
  validates :token, presence: true, uniqueness: true
  validates :device_id, presence: true
  validates :user_id, presence: true

  scope :active, -> { where(active: true) }

  before_create :check_multiple_devices

  private

  def check_multiple_devices
    return if user.master? # Masters podem ter múltiplos dispositivos
    active_keys = user.api_keys.active.where.not(id: id || -1) # Exclui o registro atual
    if active_keys.exists? && active_keys.where.not(device_id: device_id).exists?
      errors.add(:device_id, "não pode ser usado em múltiplos dispositivos para este usuário")
      throw :abort
    end
  end
end