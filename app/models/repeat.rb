class Repeat < ApplicationRecord
    has_many :training_exercise_repeats, dependent: :destroy
    has_many :training_exercises, through: :training_exercise_repeats
  
    validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  end