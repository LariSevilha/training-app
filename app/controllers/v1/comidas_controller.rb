module Api
    module V1
      class ComidasController < ApplicationController
        before_action :set_comida, only: [:show, :update, :destroy]
        
        def index
          @comidas = Comida.all
          render json: @comidas
        end
        
        def show
          render json: @comida
        end
        
        def create
          @comida = Comida.new(comida_params)
          
          if @comida.save
            render json: @comida, status: :created
          else
            render json: @comida.errors, status: :unprocessable_entity
          end
        end
        
        def update
          if @comida.update(comida_params)
            render json: @comida
          else
            render json: @comida.errors, status: :unprocessable_entity
          end
        end
        
        def destroy
          @comida.destroy
          head :no_content
        end
        
        private
        
        def set_comida
          @comida = Comida.find(params[:id])
        end
        
        def comida_params
          params.require(:comida).permit(:name, :amount_meal_id, :meal_id)
        end
      end
    end
end
  