class ApplicationController < ActionController::API
  before_action :authenticate_with_api_key

  private

  def authenticate_with_api_key
    auth_header = request.headers['Authorization']&.split(' ')&.last
    device_id = request.headers['Device-ID']

    Rails.logger.info("Autenticando com token: #{auth_header}, device_id: #{device_id}")

    if auth_header && device_id
      @api_key = ApiKey.find_by(token: auth_header, device_id: device_id, active: true)
      unless @api_key
        Rails.logger.error("Token inválido ou expirado: #{auth_header}")
        render json: { error: 'Token inválido ou expirado' }, status: :unauthorized
        return
      end
    else
      Rails.logger.error("Cabeçalhos de autenticação ausentes: Authorization=#{auth_header}, Device-ID=#{device_id}")
      render json: { error: 'Cabeçalhos de autenticação ausentes' }, status: :unauthorized
      return
    end

    Rails.logger.info("Autenticação bem-sucedida para api_key: #{@api_key.id}")
  end

  def current_user
    @current_user ||= if @api_key.master_user_id
                       MasterUser.find(@api_key.master_user_id)
                     elsif @api_key.user_id
                       User.find(@api_key.user_id)
                     end
  end
end