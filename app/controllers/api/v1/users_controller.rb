class Api::V1::UsersController < ApplicationController
  before_action :ensure_master, only: [:create, :update, :destroy, :unblock]
  before_action :set_user, only: [:show, :update, :destroy, :unblock]
  skip_before_action :authenticate_with_api_key, only: :login  
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
    email = params[:email] || params.dig(:user, :email)
    password = params[:password] || params.dig(:user, :password)
    device_id = params[:device_id] || params.dig(:user, :device_id)
  
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
          user_role: user.role,
          error: nil
        }, status: :ok
        return
      end
  
      # Ignorar bloqueio por acesso simultâneo para usuário master
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
        user_role: user.role,
        error: nil
      }, status: :ok
    else
      Rails.logger.info("Falha na autenticação ou conta bloqueada. Blocked: #{user.blocked}")
      render json: { error: 'Credenciais inválidas ou conta bloqueada' }, status: :unauthorized
    end
  end

  def planilha
    user = User.find_by(api_key: params[:api_key])
    if user && user.role == 'regular' && !user.blocked
      render json: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        trainings: user.trainings.as_json(only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video]),
        meals: user.meals.as_json(only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } }),
        error: nil
      }, status: :ok
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