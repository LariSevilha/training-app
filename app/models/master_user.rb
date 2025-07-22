class MasterUser < ApplicationRecord
    has_secure_password
    has_one_attached :photo
    has_many :api_keys, dependent: :destroy
    
    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
    validates :cpf, presence: true, uniqueness: true
    validates :phone_number, presence: true
    validates :cref, presence: true
    
    # Correct Active Storage validation
    validate :photo_validation
  
    def photo_url
      if photo.attached?
        begin
          Rails.application.routes.url_helpers.url_for(photo)
        rescue ArgumentError => e
          Rails.logger.error "Error generating photo_url: #{e.message}"
          Rails.application.routes.url_helpers.rails_blob_path(photo, only_path: true)
        end
      else
        nil
      end
    end
  
    private
  
    def photo_validation
      return unless photo.attached?
  
      # Check content type
      unless photo.content_type.in?(['image/png', 'image/jpeg', 'image/jpg'])
        errors.add(:photo, 'must be a PNG, JPEG, or JPG image')
      end
  
      # Check file size (less than 5 MB)
      if photo.byte_size > 5.megabytes
        errors.add(:photo, 'must be less than 5MB')
      end
    end
  end