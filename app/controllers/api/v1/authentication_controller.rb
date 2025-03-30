module Api
  module V1
    class AuthenticationController < ApplicationController
      # Pule a autenticação para ações públicas
      skip_before_action :authenticate_user!, only: [:login, :register], raise: false

      def login
        user = User.find_by(email: params[:email])
        if user && user.valid_password?(params[:password])
          # Gerar o token JWT
          token_data = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
          # Extrair apenas o token codificado (primeiro elemento do array)
          token = token_data.is_a?(Array) ? token_data.first : token_data
          render json: { token: token }, status: :ok
        else
          render json: { error: 'Credenciais inválidas' }, status: :unauthorized
        end
      rescue StandardError => e
        render json: { error: "Erro interno: #{e.message}" }, status: :internal_server_error
      end

      def register
        user = User.new(user_params)
        user.role = :regular unless params[:role] == 'master'
        if user.save
          token_data = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
          token = token_data.is_a?(Array) ? token_data.first : token_data
          render json: { token: token }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def logout
        Warden::JWTAuth::UserDecoder.new.call(request.headers['Authorization'].split.last)
        head :no_content
      end

      private

      def user_params
        params.permit(:email, :password, :name, :age, :weight, :height, :fitness_level)
      end
    end
  end
end