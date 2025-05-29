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

  private

  def set_dates
    self.registration_date ||= Time.current
    self.expiration_date = registration_date + 1.month
  end
end