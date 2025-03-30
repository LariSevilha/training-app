class User < ApplicationRecord
  devise :database_authenticatable, :registerable

  enum :role, { master: 0, regular: 1 }, default: :regular

  has_many :trainings, dependent: :destroy
  has_many :meals, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :api_key, uniqueness: true, allow_nil: true

  before_save :generate_api_key, if: :new_record?

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(16)
  end
end