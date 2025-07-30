class SuperUser < ApplicationRecord
  has_secure_password
  has_many :api_keys, dependent: :destroy
  has_one_attached :photo

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  def role
    'super'
  end

  def photo_url
    return nil unless photo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(photo, only_path: true)
  rescue StandardError => e
    Rails.logger.error "Error generating photo URL: #{e.message}"
    nil
  end
end