class MasterUser < ApplicationRecord
  has_secure_password
  has_many :api_keys, dependent: :destroy
  has_many :users, dependent: :destroy
  has_one_attached :photo

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :cpf, presence: true, uniqueness: true
  validates :cref, presence: true, uniqueness: true
  validates :phone_number, presence: true

  # Callback para normalizar CPF antes de salvar
  before_save :normalize_cpf

  def role
    'master'
  end

  def photo_url
    return nil unless photo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(photo, only_path: true)
  rescue StandardError => e
    Rails.logger.error "Error generating photo URL: #{e.message}"
    nil
  end

  def active?
    api_keys.where(active: true).exists?
  end

  private

  def normalize_cpf
    self.cpf = cpf.gsub(/\D/, '') if cpf.present?
  end
end