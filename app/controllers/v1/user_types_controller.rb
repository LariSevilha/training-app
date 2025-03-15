module Api
    module V1
      class UserTypesController < ApplicationController
        before_action :set_user_type, only: [:show, :update, :destroy]
        
        def index
          @user_types = UserType.all
          render json: @user_types
        end
        
        def show
          render json: @user_type
        end
        
        def create
          @user_type = UserType.new(user_type_params)
          
          if @user_type.save
            render json: @user_type, status: :created
          else
            render json: @user_type.errors, status: :unprocessable_entity
          end
        end
        
        def update
          if @user_type.update(user_type_params)
            render json: @user_type
          else
            render json: @user_type.errors, status: :unprocessable_entity
          end
        end
        
        def destroy
          @user_type.destroy
          head :no_content
        end
        
        private
        
        def set_user_type
          @user_type = UserType.find(params[:id])
        end
        
        def user_type_params
          params.require(:user_type).permit(:permission)
        end
      end
    end
  end
  