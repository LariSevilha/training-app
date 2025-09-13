# No TrainingExercise model
class TrainingExercise < ApplicationRecord
    belongs_to :training
    belongs_to :exercise, optional: true
    has_many :training_exercise_sets, dependent: :destroy
  
    accepts_nested_attributes_for :training_exercise_sets, allow_destroy: true
    
    # Atributos virtuais para receber dados do formulário
    attr_accessor :exercise_name, :video
    
    before_validation :find_or_create_exercise
    
    private
    
    def find_or_create_exercise
      return if exercise_id.present? || exercise_name.blank?
      
      self.exercise = Exercise.find_or_create_by(name: exercise_name) do |e|
        e.video = video if video.present?
      end
    end
  end