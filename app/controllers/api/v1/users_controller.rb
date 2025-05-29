# app/controllers/api/v1/users_controller.rb

class Api::V1::UsersController < ApplicationController
  before_action :ensure_master, only: [:create, :update, :destroy, :unblock]
  before_action :set_user, only: [:show, :update, :destroy, :unblock]
  skip_before_action :authenticate_with_api_key, only: :login
  respond_to :json

  def index
    users = User.where(role: :regular).includes(:trainings, :weekly_pdfs, meals: :comidas)
    render json: users.as_json(
      only: [:id, :name, :email, :role, :registration_date, :expiration_date],
      include: {
        trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description] },
        weekly_pdfs: { only: [:id, :weekday, :pdf_url] }, # Ensure pdf_url is included
        meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def show
    render json: @user.as_json(
      only: [:id, :name, :email, :role, :registration_date, :expiration_date],
      include: {
        trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :weekday, :photos_urls, :description] },
        weekly_pdfs: { only: [:id, :weekday, :pdf_url] }, # Ensure pdf_url is included
        meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def create
    user = User.new(user_params)
    user.role = :regular
    Rails.logger.info "Parâmetros recebidos: #{user_params.inspect}"
    if user.save
      render json: user.as_json(
        only: [:id, :name, :email, :role, :registration_date, :expiration_date],
        include: {
          trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description] },
          weekly_pdfs: { only: [:id, :weekday, :pdf_url] }, # Ensure pdf_url is included
          meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
        }
      ), status: :created
    else
      Rails.logger.error "Erros ao salvar: #{user.errors.full_messages}"
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    Rails.logger.info "Parâmetros recebidos: #{user_params.inspect}"
    if @user.update(user_params)
      render json: @user.as_json(
        only: [:id, :name, :email, :role, :registration_date, :expiration_date],
        include: {
          trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :photos_urls, :description] },
          weekly_pdfs: { only: [:id, :weekday, :pdf_url] }, # Ensure pdf_url is included
          meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
        }
      ), status: :ok
    else
      Rails.logger.error "Erros ao atualizar: #{@user.errors.full_messages}"
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

    if user.expired?
      user.block_account!
      render json: { error: 'Conta expirada. Entre em contato com o administrador.' }, status: :unauthorized
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
      if user.expired?
        user.block_account!
        render json: { error: 'Conta expirada. Entre em contato com o administrador.' }, status: :unauthorized
        return
      end
      render json: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        registration_date: user.registration_date,
        expiration_date: user.expiration_date,
        trainings: user.trainings.as_json(only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description]),
        meals: user.meals.as_json(only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } }),
        weekly_pdfs: user.weekly_pdfs.as_json(only: [:id, :weekday, :pdf_url]), 
        error: nil
      }, status: :ok
    else
      render json: { error: 'Acesso não autorizado' }, status: :unauthorized
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Usuário não encontrado' }, status: :not_found
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :password, :role, :registration_date,
      trainings_attributes: [
        :id, :serie_amount, :repeat_amount, :exercise_name, :video, :weekday, :description, :_destroy,
        photos: [],
        training_photos_attributes: [:id, :image_url, :_destroy]
      ],
      meals_attributes: [
        :id, :meal_type, :weekday, :_destroy,
        comidas_attributes: [:id, :name, :amount, :_destroy]
      ],
      weekly_pdfs_attributes: [
        :id, :weekday, :pdf, :_destroy 
      ]
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
    end
  end
end