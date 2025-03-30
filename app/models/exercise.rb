class Exercise < ApplicationRecord
  has_many :trainings, dependent: :destroy

  validates :name, presence: true
end
