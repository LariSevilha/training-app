# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < ApplicationController
      before_action :authorize_master!, only: [:index, :create, :update, :destroy]
      before_action :set_user, only: [:show, :update, :destroy]

      def index
        users = User.all
        render json: users, each_serializer: SimpleUserSerializer, status: :ok
      end

      def show
        render json: @user, serializer: UserSerializer, status: :ok
      end

      def create
        user = User.new(user_params)
        if user.save
          render json: user, serializer: UserSerializer, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          render json: @user, serializer: UserSerializer, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @user.destroy
        render json: { message: 'Usuário excluído com sucesso' }, status: :ok
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(
          :name, :email, :password, :role,
          trainings_attributes: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :_destroy],
          meals_attributes: [:id, :meal_type, :_destroy, comidas_attributes: [:id, :name, :amount, :_destroy]]
        )
      end

      def authorize_master!
        render json: { error: 'Acesso negado' }, status: :forbidden unless current_user&.role == 'master'
      end
    end
  end
end