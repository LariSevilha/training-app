# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_many :api_keys, dependent: :destroy
  has_many :trainings, dependent: :destroy
  has_many :meals, dependent: :destroy
  has_many :weekly_pdfs, dependent: :destroy

  accepts_nested_attributes_for :weekly_pdfs, allow_destroy: true
  accepts_nested_attributes_for :trainings, allow_destroy: true
  accepts_nested_attributes_for :meals, allow_destroy: true

  before_save :set_dates
  before_save :format_phone_number

  enum :role, { master: 0, regular: 1 }, default: :regular
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :phone_number, presence: true, format: { 
    with: /\A(\+?55)?[\s\-\(\)]?[1-9]{2}[\s\-\(\)]?[0-9]{4,5}[\s\-]?[0-9]{4}\z/, 
    message: "deve ser um número brasileiro válido (ex.: 11999999999, +5511999999999)" 
  }
  validates :plan_duration, inclusion: { in: %w[monthly semi_annual annual], allow_nil: true }
  validates :plan_type, inclusion: { in: %w[manual pdf], allow_nil: true }

  attribute :blocked, :boolean, default: false

  def block_account!
    update!(blocked: true)
  end

  def unblock_account!
    update!(blocked: false)
  end

  def expired?
    return false if role == 'master'
    expiration_date.present? && expiration_date < Time.current
  end

  # Corrigir o método expiration_date - estava usando 'object' incorretamente
  def formatted_expiration_date
    expiration_date&.strftime("%Y-%m-%d")
  end

  private

  def set_dates
    self.registration_date ||= Time.current
    case plan_duration
    when 'annual'
      self.expiration_date = registration_date + 12.months
    when 'semi_annual'
      self.expiration_date = registration_date + 6.months
    when 'monthly'
      self.expiration_date = registration_date + 1.month
    else
      self.expiration_date = registration_date + 1.month  
    end
  end

  def format_phone_number
    return unless phone_number.present?
    
    # Remove todos os caracteres não numéricos
    clean_number = phone_number.gsub(/\D/, '')
    
    # Se não começar com 55 (código do Brasil), adicionar
    unless clean_number.start_with?('55')
      clean_number = "55#{clean_number}"
    end
    
    self.phone_number = clean_number
  end
  
  def generate_password_reset_token
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.current
    save!
  end
end