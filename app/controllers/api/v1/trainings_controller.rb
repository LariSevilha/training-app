module Api
    module V1
      class TrainingsController < ApplicationController
        before_action :authenticate_user
        before_action :set_user
        before_action :set_training, only: [:show, :update, :destroy]
  
        def index
          @trainings = @user.trainings.includes(training_exercises: [:exercise, :training_exercise_sets])
          render json: @trainings, include: { training_exercises: { include: [:exercise, :training_exercise_sets] } }
        end
  
        def show
          render json: @training, include: { training_exercises: { include: [:exercise, :training_exercise_sets] } }
        end
  
        def create
          @training = @user.trainings.new(training_params)
          if @training.save
            render json: @training, include: { training_exercises: { include: [:exercise, :training_exercise_sets] } }, status: :created
          else
            render json: { errors: @training.errors.full_messages }, status: :unprocessable_entity
          end
        end
  
        def update
          if @training.update(training_params)
            render json: @training, include: { training_exercises: { include: [:exercise, :training_exercise_sets] } }
          else
            render json: { errors: @training.errors.full_messages }, status: :unprocessable_entity
          end
        end
  
        def destroy
          @training.destroy
          head :no_content
        end
  
        private
  
        def set_user
          @user = User.find(params[:user_id])
        end
  
        def set_training
          @training = @user.trainings.find(params[:id])
        end
  
        def training_params
          params.require(:training).permit(
            :weekday,
            :description,
            training_exercises_attributes: [
              :id,
              :exercise_id,
              :_destroy,
              training_exercise_sets_attributes: [
                :id,
                :series_amount,
                :repeats_amount,
                :_destroy
              ]
            ]
          )
        end
      end
    end
  end