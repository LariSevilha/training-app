class TrainingPhoto < ApplicationRecord
  belongs_to :training
  validates :image_url, presence: true
end
