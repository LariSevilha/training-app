class Api::V1::AuthenticationController < ApplicationController
  skip_before_action :verify_authenticity_token

  def login
    user = User.find_by(email: params[:email])
    if user&.valid_password?(params[:password])
      token = JWT.encode({ user_id: user.id, exp: 24.hours.from_now.to_i }, 'sua_chave_secreta')
      render json: { token: token, user: user.as_json(only: [:id, :email, :name, :user_type]) }, status: :ok
    else
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  end

  def register
    user = User.new(user_params)
    if user.save
      token = JWT.encode({ user_id: user.id, exp: 24.hours.from_now.to_i }, 'sua_chave_secreta')
      render json: { token: token, user: user.as_json(only: [:id, :email, :name, :user_type]) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:email, :password, :name, :age, :weight, :height, :fitness_level, :user_type)
  end
end