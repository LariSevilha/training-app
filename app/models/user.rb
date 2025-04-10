class User < ApplicationRecord
  has_secure_password
  has_many :api_keys, dependent: :destroy
  has_many :trainings, dependent: :destroy
  has_many :meals, dependent: :destroy

  accepts_nested_attributes_for :trainings, allow_destroy: true
  accepts_nested_attributes_for :meals, allow_destroy: true

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
end