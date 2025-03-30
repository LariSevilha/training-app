class ApplicationController < ActionController::API
  before_action :authenticate_with_api_key # Sem except, cada controlador define suas exceções

  def current_user
    @current_user ||= User.find_by(api_key: request.headers['X-API-Key'])
  end

  def ensure_master
    unless current_user&.role == 'master'
      render json: { error: 'Acesso restrito ao Master' }, status: :forbidden
    end
  end

  private

  def authenticate_with_api_key
    unless current_user
      render json: { error: 'Chave API inválida ou ausente' }, status: :unauthorized
    end
  end
end