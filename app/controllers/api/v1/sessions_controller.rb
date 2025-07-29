module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_with_api_key, only: [:create]
      respond_to :json

      def create
        # Buscar usuário pelos diferentes tipos
        user = User.find_by(email: session_params[:email]) ||
               MasterUser.find_by(email: session_params[:email]) ||
               SuperUser.find_by(email: session_params[:email])

        if user&.authenticate(session_params[:password])
          device_id = session_params[:device_id] || request.headers['Device-ID'] || SecureRandom.hex(8)
          
          # Criar nova API key
          api_key = user.api_keys.create!(
            device_id: device_id, 
            token: SecureRandom.hex(16), 
            active: true
          )

          # Determinar o role do usuário
          user_role = case user.class.name
                     when 'SuperUser'
                       'super'
                     when 'MasterUser' 
                       'master'
                     else
                       'user'
                     end

          # Renderizar resposta no formato esperado pelo frontend
          render json: {
            api_key: api_key.token,
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              role: user_role
            },
            message: 'Login bem-sucedido'
          }, status: :ok
        else
          render json: { 
            error: 'Email ou senha inválidos' 
          }, status: :unauthorized
        end
      rescue StandardError => e
        Rails.logger.error "Erro no login: #{e.message}"
        render json: { 
          error: 'Erro interno do servidor' 
        }, status: :internal_server_error
      end

      def destroy
        api_key = request.headers['Authorization']&.split(' ')&.last
        device_id = request.headers['Device-ID']
      
        unless api_key && device_id
          render json: { 
            error: 'API key e device_id são obrigatórios' 
          }, status: :bad_request and return
        end
      
        key = ApiKey.find_by(token: api_key, device_id: device_id)
        if key
          key.update(active: false)
          render json: { 
            message: 'Sessão encerrada com sucesso', 
            invalidate_token: true 
          }, status: :ok
        else
          render json: { 
            error: 'Sessão inválida' 
          }, status: :unauthorized
        end
      end

      private

      def session_params
        params.require(:session).permit(:email, :password, :device_id)
      end

      def current_user
        nil # Return nil since we don't have authenticated user context in login
      end

      def notify_master_of_duplicate_login(user)
        master = MasterUser.first # Ajustar conforme necessário
        return unless master && master.device_token.present?

        message = {
          token: master.device_token,
          notification: {
            title: "Acesso Simultâneo Detectado",
            body: "O usuário #{user.email} tentou fazer login em um novo dispositivo."
          }
        }
        # Implementar envio de notificação
      end
    end
  end
end