module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_with_api_key, only: [:create]
      respond_to :json

      def create
        email = params[:email] || params.dig(:user, :email) || params.dig(:session, :user, :email)
        password = params[:password] || params.dig(:user, :password) || params.dig(:session, :user, :password)
        device_id = params[:device_id] || params.dig(:user, :device_id) || params.dig(:session, :user, :device_id)
      
        Rails.logger.info("Parâmetros processados: email='#{email}', device_id='#{device_id}'")
      
        unless email && password && device_id
          render json: { error: 'Email, senha e device_id são obrigatórios' }, status: :bad_request and return
        end
      
        # Buscar em todos os tipos de usuário
        user = User.find_by("LOWER(email) = ?", email.downcase) ||
               MasterUser.find_by("LOWER(email) = ?", email.downcase) ||
               SuperUser.find_by("LOWER(email) = ?", email.downcase)
               
        unless user
          render json: { error: 'Credenciais inválidas' }, status: :unauthorized and return
        end
      
        if user.authenticate(password) && (!user.respond_to?(:blocked) || !user.blocked)
          # Criar ou atualizar API key baseado no tipo de usuário
          api_key = case user.class.name
                   when 'SuperUser'
                     user.api_keys.find_or_initialize_by(device_id: device_id)
                   when 'MasterUser'
                     user.api_keys.find_or_initialize_by(device_id: device_id)
                   when 'User'
                     user.api_keys.find_or_initialize_by(device_id: device_id)
                   end
                   
          api_key.token = SecureRandom.hex(16)
          api_key.active = true
          api_key.save!
      
          # Verificação de múltiplos dispositivos apenas para User comum
          if user.is_a?(User)
            active_devices = user.api_keys.active.where.not(id: api_key.id).pluck(:device_id)
            if active_devices.present? && active_devices.exclude?(device_id)
              notify_master_of_duplicate_login(user)
              user.block_account! if user.respond_to?(:block_account!)
              render json: { error: 'Conta bloqueada devido a acesso simultâneo' }, status: :unauthorized and return
            end
          end
      
          user_type = case user.class.name
                     when 'SuperUser' then 'super'
                     when 'MasterUser' then 'master'
                     when 'User' then 'regular'
                     end
      
          render json: {
            api_key: api_key.token,
            user_type: user_type,
            user_id: user.id,
            message: 'Login realizado com sucesso'
          }, status: :ok
        else
          Rails.logger.info("Falha na autenticação ou conta bloqueada")
          render json: { error: 'Credenciais inválidas ou conta bloqueada' }, status: :unauthorized
        end
      end

      def destroy
        api_key = request.headers['Authorization']&.split(' ')&.last
        device_id = request.headers['Device-ID']
      
        unless api_key && device_id
          render json: { error: 'API key e device_id são obrigatórios' }, status: :bad_request and return
        end
      
        key = ApiKey.find_by(token: api_key, device_id: device_id)
        if key
          key.update(active: false)
          render json: { message: 'Sessão encerrada com sucesso', invalidate_token: true }, status: :ok
        else
          render json: { error: 'Sessão inválida' }, status: :unauthorized
        end
      end

      private

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