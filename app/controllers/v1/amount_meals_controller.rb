module Api
    module V1
      class AmountMealsController < ApplicationController
        before_action :set_amount_meal, only: [:show, :update, :destroy]
        
        def index
          @amount_meals = AmountMeal.all
          render json: @amount_meals
        end
        
        def show
          render json: @amount_meal
        end
        
        def create
          @amount_meal = AmountMeal.new(amount_meal_params)
          
          if @amount_meal.save
            render json: @amount_meal, status: :created
          else
            render json: @amount_meal.errors, status: :unprocessable_entity
          end
        end
        
        def update
          if @amount_meal.update(amount_meal_params)
            render json: @amount_meal
          else
            render json: @amount_meal.errors, status: :unprocessable_entity
          end
        end
        
        def destroy
          @amount_meal.destroy
          head :no_content
        end
        
        private
        
        def set_amount_meal
          @amount_meal = AmountMeal.find(params[:id])
        end
        
        def amount_meal_params
          params.require(:amount_meal).permit(:amount)
        end
      end
    end
  end