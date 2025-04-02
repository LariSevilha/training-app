class ApiKey < ApplicationRecord
    belongs_to :user
  
    validates :token, presence: true, uniqueness: true
    validates :device_id, presence: true
  
    attribute :active, :boolean, default: true
  
    scope :active, -> { where(active: true) }
  end