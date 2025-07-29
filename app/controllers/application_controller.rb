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
      Rails.logger.error("Cabeçalhos de autenticação ausentes")
      render json: { error: 'Cabeçalhos de autenticação ausentes' }, status: :unauthorized
      return
    end

    Rails.logger.info("Autenticação bem-sucedida para api_key: #{@api_key.id}")
  end

  def current_user
    return nil unless @api_key
    @current_user ||= @api_key.associated_user
  end

  def user_role
    return 'super' if current_user.is_a?(SuperUser)
    return 'master' if current_user.is_a?(MasterUser)
    return 'user' if current_user.is_a?(User)
    nil
  end
end