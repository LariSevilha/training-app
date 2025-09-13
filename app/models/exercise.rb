class Exercise < ApplicationRecord
  has_many :training_exercises, dependent: :destroy
  has_many :trainings, through: :training_exercises
end