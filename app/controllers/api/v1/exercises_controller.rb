module Api
    module V1
      class ExercisesController < ApplicationController
        before_action :authenticate_with_api_key # Fixed: Use authenticate_with_api_key
        before_action :set_exercise, only: [:show, :update, :destroy]
  
        def index
          @exercises = Exercise.all
          render json: @exercises
        end
  
        def show
          render json: @exercise
        end
  
        def create
          Rails.logger.info("Creating exercise with params: #{exercise_params.inspect}")
          @exercise = Exercise.new(exercise_params)
          if @exercise.save
            Rails.logger.info("Exercise created successfully: #{@exercise.id}")
            render json: @exercise, status: :created
          else
            Rails.logger.error("Failed to create exercise: #{@exercise.errors.full_messages}")
            render json: { errors: @exercise.errors.full_messages }, status: :unprocessable_entity
          end
        end
  
        def update
          if @exercise.update(exercise_params)
            render json: @exercise
          else
            render json: { errors: @exercise.errors.full_messages }, status: :unprocessable_entity
          end
        end
  
        def destroy
          @exercise.destroy
          head :no_content
        end
  
        private
  
        def set_exercise
          @exercise = Exercise.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Exercise not found' }, status: :not_found
        end
  
        def exercise_params
          params.require(:exercise).permit(:name, :video)
        end
      end
    end
  end