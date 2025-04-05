class ApiKey < ApplicationRecord
  belongs_to :user
  before_create :generate_token

  scope :active, -> { where(active: true) }

  private

  def generate_token
    self.token = SecureRandom.uuid
    self.active = true
  end
end