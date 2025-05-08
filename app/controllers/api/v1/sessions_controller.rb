class Api::V1::SessionsController < ApplicationController
  skip_before_action :authenticate_with_api_key, only: :create
  respond_to :json

  def create
    email = params[:email] || params.dig(:user, :email) || params.dig(:session, :user, :email)
    password = params[:password] || params.dig(:user, :password) || params.dig(:session, :user, :password)
    device_id = params[:device_id] || params.dig(:user, :device_id) || params.dig(:session, :user, :device_id)
  
    Rails.logger.info("Parâmetros processados: email='#{email}', device_id='#{device_id}'")
  
    unless email && password && device_id
      Rails.logger.info("Parâmetros ausentes. Email: #{email}, Password: #{password}, Device_id: #{device_id}")
      render json: { error: 'Email, senha e device_id são obrigatórios' }, status: :bad_request
      return
    end
  
    user = User.find_by("LOWER(email) = ?", email.downcase)
    unless user
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
      return
    end
  
    if user.authenticate(password) && !user.blocked
      existing_api_key = user.api_keys.active.find_by(device_id: device_id)
      if existing_api_key
        render json: {
          api_key: existing_api_key.token,
          device_id: device_id,
          user: { role: user.role }, # Alterado para aninhar role
          error: nil
        }, status: :ok
        return
      end
  
      unless user.master?
        if user.api_keys.active.exists? && user.api_keys.active.where.not(device_id: device_id).exists?
          notify_master_of_duplicate_login(user)
          user.block_account!
          render json: { error: 'Conta bloqueada devido a acesso simultâneo' }, status: :unauthorized
          return
        end
      end
  
      api_key = user.api_keys.create!(device_id: device_id, token: SecureRandom.uuid)
      render json: {
        api_key: api_key.token,
        device_id: device_id,
        user: { role: user.role }, # Alterado para aninhar role
        error: nil
      }, status: :ok
    else
      render json: { error: 'Credenciais inválidas ou conta bloqueada' }, status: :unauthorized
    end
  end

  def destroy
    api_key = request.headers['Authorization']&.split(' ')&.last
    device_id = request.headers['Device-ID']
  
    unless api_key && device_id
      render json: { error: 'API key e device_id são obrigatórios' }, status: :bad_request
      return
    end
  
    key = ApiKey.active.find_by(token: api_key, device_id: device_id)
    if key
      key.update(active: false)
      render json: { message: 'Sessão encerrada com sucesso' }, status: :ok
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
    # Exemplo: fcm.send([master.device_token], message)
  end
end