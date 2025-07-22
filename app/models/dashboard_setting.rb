class DashboardSetting < ApplicationRecord
    has_one_attached :logo
    
    validates :primary_color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
    validates :secondary_color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
    validates :tertiary_color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
    validates :app_name, presence: true, length: { maximum: 100 }
    
    validate :logo_format
    
    def logo_url
      return nil unless logo.attached?
      
      begin
        # Try to generate full URL
        if Rails.env.development?
          Rails.application.routes.url_helpers.rails_blob_url(logo, 
            host: 'localhost:3000', 
            protocol: 'http'
          )
        else
          # For production
          host = Rails.application.config.action_mailer.default_url_options[:host] rescue nil
          protocol = Rails.env.production? ? 'https' : 'http'
          
          if host
            Rails.application.routes.url_helpers.rails_blob_url(logo, 
              host: host, 
              protocol: protocol
            )
          else
            # Fallback to path only
            Rails.application.routes.url_helpers.rails_blob_path(logo)
          end
        end
      rescue => e
        Rails.logger.error "Error generating logo URL: #{e.message}"
        # Final fallback to path only
        Rails.application.routes.url_helpers.rails_blob_path(logo) rescue nil
      end
    end
    
    # Alternative method that always returns path (no host)
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