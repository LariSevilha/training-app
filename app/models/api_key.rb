class ApiKey < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :master_user, optional: true
  belongs_to :super_user, optional: true
  
  validates :token, presence: true, uniqueness: true
  validates :device_id, presence: true
  validate :single_user_association

  scope :active, -> { where(active: true) }
  before_create :generate_token
  before_create :check_multiple_devices

  # Método para determinar o tipo de usuário
  def user_type
    return 'SuperUser' if super_user_id.present?
    return 'MasterUser' if master_user_id.present?
    return 'User' if user_id.present?
    nil
  end

  # Método para obter o usuário associado
  def associated_user
    return super_user if super_user_id.present?
    return master_user if master_user_id.present?
    return user if user_id.present?
    nil
  end

  private

  def single_user_association
    associations = [user_id, master_user_id, super_user_id].compact
    if associations.empty?
      errors.add(:base, 'ApiKey deve pertencer a um User, MasterUser ou SuperUser')
    elsif associations.length > 1
      errors.add(:base, 'ApiKey deve pertencer a apenas um tipo de usuário')
    end
  end

  def check_multiple_devices
    return if master_user_id.present? || super_user_id.present? # Masters e SuperUsers podem ter múltiplos dispositivos
    
    if user_id.present?
      active_keys = ApiKey.active.where(user_id: user_id).where.not(id: id || -1)
      if active_keys.exists? && active_keys.where.not(device_id: device_id).exists?
        errors.add(:device_id, 'não pode ser usado em múltiplos dispositivos para este usuário')
        throw :abort
      end
    end
  end

  def generate_token
    self.token ||= SecureRandom.hex(16)
  end
end