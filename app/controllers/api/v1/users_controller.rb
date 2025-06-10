class Api::V1::UsersController < ApplicationController
  before_action :ensure_master, only: [:index, :show, :create, :update, :destroy, :unblock]
  before_action :set_user, only: [:show, :update, :destroy, :unblock]
  respond_to :json

  def index
    users = User.where(role: 'regular').includes(:trainings, :weekly_pdfs, meals: :comidas)
    render json: users.as_json(
      only: [:id, :name, :email, :role, :registration_date, :email, :plan_type, :plan_duration],
      include: {
        trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description, :weekday], methods: [:photo_urls] },
        weekly_pdfs: { only: [:id, :weekday, :pdf_url] },
        meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def show
    render json: @user.as_json(
      only: [:id, :name, :email, :role, :registration_date, :expiration_date, :plan_type, :plan_duration, :phone_number],
      include: {
        trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description, :weekday], methods: [:photo_urls] },
        weekly_pdfs: { only: [:id, :weekday, :pdf_url, :notes], methods: [:pdf_filename] },
        meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def create
    user = User.new(user_params)
    user.role = :regular
    Rails.logger.info "Parâmetros recebidos: #{user_params.inspect}"
    if user_params[:weekly_pdfs_attributes].present?
      user.weekly_pdfs.destroy_all # Garante apenas um PDF
    end
    if user.save
      WhatsappService.send_confirmation(user)
      render json: user.as_json(
        only: [:id, :name, :email, :role, :registration_date, :expiration_date, :plan_type, :plan_duration, :phone_number],
        include: {
          trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description, :weekday], methods: [:photo_urls] },
          weekly_pdfs: { only: [:id, :weekday, :pdf_url, :notes], methods: [:pdf_filename] },
          meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } }
        }
      ), status: :created
    else
      Rails.logger.error "Erros ao salvar: #{user.errors.full_messages}"
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if user_params[:weekly_pdfs_attributes].present?
      @user.weekly_pdfs.destroy_all # Garante apenas um PDF
    end
    if @user.update(user_params)
      render json: @user.as_json(
        only: [:id, :name, :email, :role, :registration_date, :expiration_date, :plan_type, :plan_duration, :phone_number],
        include: {
          trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description, :weekday], methods: [:photo_urls] },
          weekly_pdfs: { only: [:id, :weekday, :pdf_url, :notes], methods: [:pdf_filename] },
          meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } }
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

  def planilha
    user = User.find_by(api_key: params[:api_key])
    if user && user.role == 'regular' && !user.blocked
      if user.expired?
        user.block_account!
        render json: { error: 'Conta expirada. Entre em contato com o administrador.' }, status: :unauthorized
        return
      end

      response_data = {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        registration_date: user.registration_date,
        expiration_date: user.expiration_date,
        plan_type: user.plan_type,
        plan_duration: user.plan_duration,
        error: nil,
        trainings: user.trainings.as_json(
          only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :description, :weekday],
          methods: [:photo_urls]
        ),
        meals: user.meals.as_json(
          only: [:id, :meal_type, :weekday],
          include: { comidas: { only: [:id, :name, :amount] } }
        ),
        weekly_pdfs: user.weekly_pdfs.as_json(only: [:id, :weekday, :pdf_url])
      }

      global_pdf = user.weekly_pdfs.find { |pdf| pdf.weekday.nil? }
      if global_pdf
        response_data[:weekly_pdfs] = [{ id: global_pdf.id, weekday: nil, pdf_url: global_pdf.pdf_url }]
      end

      render json: response_data, status: :ok
    else
      render json: { error: 'Acesso não autorizado' }, status: :unauthorized
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Usuário não encontrado' }, status: :not_found and return
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :password, :role, :registration_date, :plan_type, :plan_duration, :phone_number,
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
        :id, :weekday, :pdf, :notes, :_destroy
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
      # Implementar envio de notificação, ex.: fcm.send([master.device_token], message)
    end
  end
end