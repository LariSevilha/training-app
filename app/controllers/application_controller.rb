class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_with_api_key

  def authenticate_with_api_key
    authenticate_or_request_with_http_token do |token, _options|
      Rails.logger.info("Authenticating with token: #{token}")
      api_key = ApiKey.active.find_by(token: token)
      if api_key
        @current_user = api_key.user
        @current_device_id = request.headers['Device-ID']
        unless @current_device_id
          Rails.logger.warn("Device-ID header missing for token: #{token}")
          render json: { error: 'Device-ID header is required' }, status: :unauthorized and return false
        end
        if api_key.device_id != @current_device_id
          Rails.logger.warn("Device ID mismatch for token: #{token}")
          render json: { error: 'Device ID mismatch' }, status: :unauthorized and return false
        end
        true
      else
        Rails.logger.warn("No active API key found for token: #{token}")
        render json: { error: 'Unauthorized' }, status: :unauthorized and return false
      end
    end
  end

  def current_user
    @current_user
  end

  private

  def ensure_master
    unless current_user&.role == 'master'
      render json: { error: 'Apenas o master pode realizar esta ação' }, status: :forbidden and return
    end
  end
end