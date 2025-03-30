class Training < ApplicationRecord
  belongs_to :user
  belongs_to :serie
  belongs_to :repeat
  belongs_to :exercise

  validates :user_id, presence: true
  validates :serie_id, presence: true
  validates :repeat_id, presence: true
  validates :exercise_id, presence: true
end
