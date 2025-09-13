class TrainingExerciseSet < ApplicationRecord
    belongs_to :training_exercise
  
    validates :series_amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :repeats_amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  end