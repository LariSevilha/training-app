class Training < ApplicationRecord
  belongs_to :user
  validates :exercise_name, presence: true
  validates :serie_amount, :repeat_amount, numericality: { greater_than_or_equal_to: 0 }
end