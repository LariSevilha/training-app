class Api::V1::UsersController < ApplicationController
  before_action :ensure_master, only: [:create, :update, :destroy, :unblock]
  before_action :set_user, only: [:show, :update, :destroy, :unblock]
  respond_to :json

  def index
    users = User.where(role: :regular).includes(:trainings, meals: :comidas)
    render json: users.as_json(
      only: [:id, :name, :email, :role],
      include: {
        trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video] },
        meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def show
    render json: @user.as_json(
      only: [:id, :name, :email, :role],
      include: {
        trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video] },
        meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def create
    user = User.new(user_params)
    user.role = :regular # Forçar role como regular para novos usuários
  
    if user.save
      render json: user.as_json(
        only: [:id, :name, :email, :role],
        include: {
          trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video] },
          meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
        }
      ), status: :created
    else
      # Adicionar mais detalhes aos erros para depuração
      Rails.logger.info("Erros de validação: #{user.errors.full_messages}")
      Rails.logger.info("Usuário: #{user.inspect}")
      user.meals.each do |meal|
        Rails.logger.info("Meal: #{meal.inspect}")
        meal.comidas.each do |comida|
          Rails.logger.info("Comida: #{comida.inspect}")
        end
      end
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: @user.as_json(
        only: [:id, :name, :email, :role],
        include: {
          trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video] },
          meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
        }
      ), status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    render json: { message: 'Usuário deletado com sucesso' }, status: :ok
  end

  def unblock
    @user.unblock_account!
    render json: { message: 'Conta desbloqueada' }, status: :ok
  end

  def login
    user_params = params[:user] || {}
    email = user_params[:email]
    password = user_params[:password]
    device_id = user_params[:device_id]

    unless email && password && device_id
      render json: { error: 'Email, senha e device_id são obrigatórios' }, status: :bad_request
      return
    end

    user = User.find_by(email: email)
    unless user
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
      return
    end

    if user.authenticate(password) && !user.blocked
      existing_api_key = user.api_keys.active.find_by(device_id: device_id)
      if existing_api_key
        render json: { api_key: existing_api_key.token, user: { id: user.id, email: user.email, role: user.role } }, status: :ok
        return
      end

      if user.api_keys.active.exists? && user.api_keys.active.where.not(device_id: device_id).exists?
        notify_master_of_duplicate_login(user)
        user.block_account!
        render json: { error: 'Conta bloqueada devido a acesso simultâneo' }, status: :unauthorized
        return
      end

      api_key = user.api_keys.create!(device_id: device_id, token: SecureRandom.uuid)
      render json: { api_key: api_key.token, user: { id: user.id, email: user.email, role: user.role } }, status: :ok
    else
      render json: { error: 'Credenciais inválidas ou conta bloqueada' }, status: :unauthorized
    end
  end

  def planilha
    user = User.find_by(api_key: params[:api_key])
    if user && user.role == 'regular' && !user.blocked
      render html: <<-HTML.html_safe
        <!DOCTYPE html>
        <html>
        <head>
          <title>Planilha</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            h1 { color: #333; }
            h2 { color: #555; }
            ul { list-style-type: none; padding: 0; }
            li { margin: 10px 0; }
          </style>
        </head>
        <body>
          <h1>Planilha de #{user.name}</h1>
          <h2>Treinos</h2>
          <ul>
            #{user.trainings.map { |t| "<li>#{t.exercise_name}: #{t.serie_amount} séries, #{t.repeat_amount} repetições</li>" }.join}
          </ul>
          <h2>Dietas</h2>
          <ul>
            #{user.meals.map { |m| "<li>#{m.meal_type}: #{m.comidas.map { |c| "#{c.name} (#{c.amount})" }.join(', ')}</li>" }.join}
          </ul>
        </body>
        </html>
      HTML
    else
      render json: { error: 'Acesso não autorizado' }, status: :unauthorized
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :password, :role,
      trainings_attributes: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :_destroy],
      meals_attributes: [:id, :meal_type, :_destroy, comidas_attributes: [:id, :name, :amount, :_destroy]]
    )
  end

  def notify_master_of_duplicate_login(user)
    master = User.find_by(role: :master)
    return unless master

    if master.device_token.present?
      message = {
        token: master.device_token,
        notification: {
          title: "Acesso Simultâneo Detectado",
          body: "O usuário #{user.email} tentou fazer login em um novo dispositivo."
        }
      }
      # Enviar a notificação (ex.: usando a gem 'fcm')
      # fcm = FCM.new("sua-chave-de-servidor-fcm")
      # fcm.send([master.device_token], message)
    end
  end
end