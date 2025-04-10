class Api::V1::SessionsController < ApplicationController
  skip_before_action :authenticate_with_api_key, only: :create
  respond_to :json

  def create
    user_params = params[:user] || params[:session] || params.permit(:email, :password, :device_id)
    email = user_params[:email]
    password = user_params[:password]
    device_id = user_params[:device_id]

    user = User.find_by(email: email)
    if user&.authenticate(password) # Substituí valid_password? por authenticate
      api_key = user.api_keys.active.find_by(device_id: device_id)&.token || user.api_keys.create!(device_id: device_id, token: SecureRandom.uuid).token
      render json: { api_key: api_key, user: { id: user.id, email: user.email, role: user.role }, message: 'Login bem-sucedido' }, status: :ok
    else
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  end
end