module Api
    module V1
      class TrainingsController < ApplicationController
        before_action :set_training, only: [:show, :update, :destroy]
        
        def index
          @trainings = Training.all
          render json: @trainings
        end
        
        def show
          render json: @training
        end
        def user_trainings
           @trainings = Training.where(user_id: params[:user_id])
           render json: @trainings
        end
        def create
          @training = Training.new(training_params)
          
          if @training.save
            render json: @training, status: :created
          else
            render json: @training.errors, status: :unprocessable_entity
          end
        end
        
        def update
          if @training.update(training_params)
            render json: @training
          else
            render json: @training.errors, status: :unprocessable_entity
          end
        end
        
        def destroy
          @training.destroy
          head :no_content
        end
        
        private
        
        def set_training
          @training = Training.find(params[:id])
        end
        
        def training_params
          params.require(:training).permit(:user_id, :serie_id, :repeat_id, :exercise_id)
        end
      end
    end
end