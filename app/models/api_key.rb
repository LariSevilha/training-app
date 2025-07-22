class ApiKey < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :master_user, optional: true
  validates :token, presence: true, uniqueness: true
  validates :device_id, presence: true
  validate :user_or_master_user_present

  scope :active, -> { where(active: true) }

  before_create :check_multiple_devices

  private

  def user_or_master_user_present
    unless user_id.present? || master_user_id.present?
      errors.add(:base, 'ApiKey deve pertencer a um User ou MasterUser')
    end
    if user_id.present? && master_user_id.present?
      errors.add(:base, 'ApiKey não pode pertencer a User e MasterUser ao mesmo tempo')
    end
  end

  def check_multiple_devices
    return if master_user # Masters podem ter múltiplos dispositivos
    if user
      active_keys = user.api_keys.active.where.not(id: id || -1) # Exclui o registro atual
      if active_keys.exists? && active_keys.where.not(device_id: device_id).exists?
        errors.add(:device_id, 'não pode ser usado em múltiplos dispositivos para este usuário')
        throw :abort
      end
    end
  end
end