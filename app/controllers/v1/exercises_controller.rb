module Api
    module V1
      class ExercisesController < ApplicationController
        before_action :set_exercise, only: [:show, :update, :destroy]
        
        def index
          @exercises = Exercise.all
          render json: @exercises
        end
        
        def show
          render json: @exercise
        end
        
        def create
          @exercise = Exercise.new(exercise_params)
          
          if @exercise.save
            render json: @exercise, status: :created
          else
            render json: @exercise.errors, status: :unprocessable_entity
          end
        end
        
        def update
          if @exercise.update(exercise_params)
            render json: @exercise
          else
            render json: @exercise.errors, status: :unprocessable_entity
          end
        end
        
        def destroy
          @exercise.destroy
          head :no_content
        end
        
        def search
            exercises = Exercise.where("name LIKE ?", "%#{params[:keyword]}%")
            render json: @exercises
        end
        
        def video
          @exercise = Exercise.find(params[:id])
          render json: { video_url: @exercise.video }
        end

        private
        
        def set_exercise
          @exercise = Exercise.find(params[:id])
        end
        
        def exercise_params
          params.require(:exercise).permit(:name, :video)
        end
      end
    end
  end  