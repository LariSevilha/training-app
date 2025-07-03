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
  enum :role, { master: 0, regular: 1 }, default: :regular
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  # validates :phone_number, presence: true, format: { with: /\A\+?\d{10,15}\z/, message: "deve ser um número válido (ex.: +5511999999999)" }
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

  def formatted_expiration_date
    expiration_date&.strftime("%Y-%m-%d")
  end

  private

  def set_dates
    self.registration_date ||= Time.current
    if new_record? || saved_change_to_plan_duration? || saved_change_to_registration_date?
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
  end
end