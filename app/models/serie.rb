class Series < ApplicationRecord
    has_many :training_exercise_series, dependent: :destroy
    has_many :training_exercises, through: :training_exercise_series
  
    validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  end