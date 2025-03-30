# app/controllers/api/v1/sessions_controller.rb
class Api::V1::SessionsController < ApplicationController
    skip_before_action :authenticate_with_api_key, only: :create
    respond_to :json
  
    def create
        user = User.find_by(email: params[:user][:email])
        if user&.valid_password?(params[:user][:password])
          render json: { api_key: user.api_key, user: { id: user.id, email: user.email, role: user.role }, message: 'Login bem-sucedido' }, status: :ok
        else
          render json: { error: 'Credenciais inválidas' }, status: :unauthorized
        end
      end
  end