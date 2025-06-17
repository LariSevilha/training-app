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
          Rails.logger.info("Parâmetros ausentes. Email: #{email}, Password: #{password}, Device_id: #{device_id}")
          render json: { error: 'Email, senha e device_id são obrigatórios' }, status: :bad_request and return
        end

        user = User.find_by("LOWER(email) = ?", email.downcase)
        unless user
          render json: { error: 'Credenciais inválidas' }, status: :unauthorized and return
        end

        if user.expired?
          user.block_account!
          render json: { error: 'Conta expirada. Entre em contato com o administrador.' }, status: :unauthorized and return
        end

        if user.authenticate(password) && !user.blocked
          # Verifica ou cria/update ApiKey para o device_id atual
          api_key = user.api_keys.find_or_initialize_by(device_id: device_id) do |key|
            key.token = SecureRandom.uuid
            key.active = true
          end
          api_key.update!(token: SecureRandom.uuid, active: true) unless api_key.persisted? || api_key.active?

          # Verifica múltiplos dispositivos para usuários não-master
          unless user.master?
            active_devices = user.api_keys.active.where.not(id: api_key.id).pluck(:device_id)
            if active_devices.present? && active_devices.exclude?(device_id)
              notify_master_of_duplicate_login(user)
              user.block_account!
              render json: { error: 'Conta bloqueada devido a acesso simultâneo' }, status: :unauthorized and return
            end
          end

          render json: {
            api_key: api_key.token,
            role: user.role,
            message: 'Login realizado com sucesso'
          }, status: :ok
        else
          Rails.logger.info("Falha na autenticação ou conta bloqueada. Blocked: #{user.blocked}")
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

      def notify_master_of_duplicate_login(user)
        master = User.find_by(role: :master)
        return unless master && master.device_token.present?

        message = {
          token: master.device_token,
          notification: {
            title: "Acesso Simultâneo Detectado",
            body: "O usuário #{user.email} tentou fazer login em um novo dispositivo."
          }
        }
        # Implementar envio de notificação, ex.: fcm.send([master.device_token], message)
      end
    end
  end
end