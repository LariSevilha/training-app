module Api
    module V1
      class SeriesController < ApplicationController
        before_action :set_serie, only: [:show, :update, :destroy]
        
        def index
          @series = Serie.all
          render json: @series
        end
        
        def show
          render json: @serie
        end
        
        def create
          @serie = Serie.new(serie_params)
          
          if @serie.save
            render json: @serie, status: :created
          else
            render json: @serie.errors, status: :unprocessable_entity
          end
        end
        
        def update
          if @serie.update(serie_params)
            render json: @serie
          else
            render json: @serie.errors, status: :unprocessable_entity
          end
        end
        
        def destroy
          @serie.destroy
          head :no_content
        end
        
        private
        
        def set_serie
          @serie = Serie.find(params[:id])
        end
        
        def serie_params
          params.require(:serie).permit(:amount)
        end
      end
    end
  end