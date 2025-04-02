class User < ApplicationRecord
  # devise :database_authenticatable, :registerable 
  has_secure_password
  enum role: { regular: 0, master: 1 }
  has_many :trainings, dependent: :destroy
  has_many :meals, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :api_key, uniqueness: true, allow_nil: true
  has_many :api_keys, dependent: :destroy
  before_save :generate_api_key, if: :new_record?
  attribute :blocked, :boolean, default: false
  attribute :role, :string
  def block_account!
    update!(blocked: true, active_device_id: nil)
  end

  def unblock_account!
    update!(blocked: false)
  end

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(16)
  end
end