class DashboardSetting < ApplicationRecord
    has_one_attached :logo
    validates :primary_color, presence: true
    validates :secondary_color, presence: true
    validates :tertiary_color, presence: true
    validates :app_name, presence: true
    
    # Use custom validation for ActiveStorage attachment
    validate :logo_validation
  
    def logo_url
      if logo.attached?
        begin
          Rails.application.routes.url_helpers.url_for(logo)
        rescue ArgumentError => e
          Rails.logger.error "Error generating logo_url: #{e.message}"
          nil
        end
      else
        nil
      end
    end
  
    private
  
    def logo_validation
      return unless logo.attached?
  
      # Check content type
      unless logo.content_type.in?(['image/png', 'image/jpeg', 'image/jpg'])
        errors.add(:logo, 'must be a PNG, JPEG, or JPG image')
      end
  
      # Check file size (less than 5 MB)
      if logo.byte_size > 5.megabytes
        errors.add(:logo, 'must be less than 5MB')
      end
    end
  end