class Training < ApplicationRecord
  belongs_to :user
  validates :serie_amount, presence: true
  validates :repeat_amount, presence: true
  validates :exercise_name, presence: true
end