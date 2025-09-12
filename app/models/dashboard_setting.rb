class DashboardSetting < ApplicationRecord
  # Associar com MasterUser para ter configurações específicas por master
  belongs_to :master_user, optional: true
  
  has_one_attached :logo
  
  validates :primary_color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
  validates :secondary_color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
  validates :tertiary_color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
  validates :app_name, presence: true, length: { maximum: 100 } 
  
  validate :logo_format
  
  # Método para buscar configuração específica do usuário ou global
  def self.for_user(user)
    case user
    when MasterUser
      user.dashboard_setting || global_setting
    when SuperUser
      global_setting
    when User
      user.master_user&.dashboard_setting || global_setting
    else
      global_setting
    end
  end
  
  # Configuração global (para SuperUsers ou fallback)
  def self.global_setting
    where(master_user_id: nil).first
  end
  
  def logo_url
    return nil unless logo.attached?
    
    begin
      if Rails.env.development?
        Rails.application.routes.url_helpers.rails_blob_url(logo, 
          host: 'localhost:3000', 
          protocol: 'http'
        )
      else
        host = Rails.application.config.action_mailer.default_url_options[:host] rescue nil
        protocol = Rails.env.production? ? 'https' : 'http'
        
        if host
          Rails.application.routes.url_helpers.rails_blob_url(logo, 
            host: host, 
            protocol: protocol
          )
        else
          Rails.application.routes.url_helpers.rails_blob_path(logo)
        end
      end
    rescue => e
      Rails.logger.error "Error generating logo URL: #{e.message}"
      Rails.application.routes.url_helpers.rails_blob_path(logo) rescue nil
    end
  end
  
  def logo_path
    return nil unless logo.attached?
    Rails.application.routes.url_helpers.rails_blob_path(logo)
  end
  
  private
  
  def logo_format
    return unless logo.attached?
    
    unless logo.blob.content_type.in?(['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'image/webp'])
      errors.add(:logo, 'deve ser uma imagem válida (PNG, JPG, JPEG, GIF, WEBP)')
    end
    
    if logo.blob.byte_size > 5.megabytes
      errors.add(:logo, 'deve ter menos de 5MB')
    end
  end
end