module Api
    module V1
      class RepeatsController < ApplicationController
        before_action :set_repeat, only: [:show, :update, :destroy]
        
        def index
          @repeats = Repeat.all
          render json: @repeats
        end
        
        def show
          render json: @repeat
        end
        
        def create
          @repeat = Repeat.new(repeat_params)
          
          if @repeat.save
            render json: @repeat, status: :created
          else
            render json: @repeat.errors, status: :unprocessable_entity
          end
        end
        
        def update
          if @repeat.update(repeat_params)
            render json: @repeat
          else
            render json: @repeat.errors, status: :unprocessable_entity
          end
        end
        
        def destroy
          @repeat.destroy
          head :no_content
        end
        
        private
        
        def set_repeat
          @repeat = Repeat.find(params[:id])
        end
        
        def repeat_params
          params.require(:repeat).permit(:amount)
        end
      end
    end
  end