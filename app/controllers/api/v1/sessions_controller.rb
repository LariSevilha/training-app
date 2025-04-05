module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_with_api_key, only: :create

      def create
        user = User.find_by(email: params[:email])
        unless user&.authenticate(params[:password])
          render json: { error: 'Credenciais inválidas' }, status: :unauthorized
          return
        end

        if user.blocked
          render json: { error: 'Conta bloqueada' }, status: :forbidden
          return
        end

        device_id = params[:device_id]
        api_key = user.api_keys.create!(device_id: device_id)
        render json: { api_key: api_key.token, user: { id: user.id, email: user.email, role: user.role }, message: 'Login bem-sucedido' }, status: :ok
      end

      def destroy
        api_key = ApiKey.active.find_by(token: request.headers['Authorization']&.split&.last)
        if api_key
          api_key.update!(active: false)
          render json: { message: 'Logout bem-sucedido' }, status: :ok
        else
          render json: { error: 'Não autorizado' }, status: :unauthorized
        end
      end
    end
  end
end