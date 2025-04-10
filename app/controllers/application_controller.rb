class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_with_api_key

  def authenticate_with_api_key
    authenticate_or_request_with_http_token do |token, _options|
      api_key = ApiKey.active.find_by(token: token)
      if api_key
        @current_user = api_key.user
        @current_device_id = request.headers['Device-ID']
        if @current_device_id && api_key.device_id != @current_device_id
          render json: { error: "Device ID mismatch" }, status: :unauthorized
          return false
        end
        true
      else
        render json: { error: "Unauthorized" }, status: :unauthorized
        false
      end
    end
  end

  def current_user
    @current_user
  end

  private

  def ensure_master
    unless current_user&.role == 'master'
      render json: { error: 'Apenas o master pode realizar esta ação' }, status: :forbidden
    end
  end
end