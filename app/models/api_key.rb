class ApiKey < ApplicationRecord
  belongs_to :user
  validates :token, presence: true, uniqueness: true
  validates :device_id, presence: true
  validates :user_id, presence: true

  scope :active, -> { where(active: true) }
end