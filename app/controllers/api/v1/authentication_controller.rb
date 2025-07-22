module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_with_api_key, only: [:login, :register], raise: false

      def login
        email = params[:email]&.downcase
        unless email
          render json: { error: 'Email é obrigatório' }, status: :bad_request and return
        end

        user = User.find_by("LOWER(email) = ?", email) || MasterUser.find_by("LOWER(email) = ?", email)
        if user && user.valid_password?(params[:password])
          token_data = Warden::JWTAuth::UserEncoder.new.call(user, user.is_a?(MasterUser) ? :master_user : :user, nil)
          token = token_data.is_a?(Array) ? token_data.first : token_data
          render json: { token: token, user_type: user.is_a?(MasterUser) ? 'master' : 'regular' }, status: :ok
        else
          render json: { error: 'Credenciais inválidas' }, status: :unauthorized
        end
      rescue StandardError => e
        Rails.logger.error("Erro no login: #{e.message}\nBacktrace: #{e.backtrace.join("\n")}")
        render json: { error: "Erro interno: #{e.message}" }, status: :internal_server_error
      end

      def register
        if params[:user_type] == 'master'
          user = MasterUser.new(master_user_params)
        else
          user = User.new(user_params)
        end

        if user.save
          token_data = Warden::JWTAuth::UserEncoder.new.call(user, user.is_a?(MasterUser) ? :master_user : :user, nil)
          token = token_data.is_a?(Array) ? token_data.first : token_data
          render json: { token: token, user_type: user.is_a?(MasterUser) ? 'master' : 'regular' }, status: :created
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
        params.permit(:email, :password, :name, :age, :weight, :height, :fitness_level, :phone_number)
      end

      def master_user_params
        params.permit(:email, :password, :name, :phone_number, :cpf, :cref)
      end
    end
  end
end