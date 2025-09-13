class Api::V1::UsersController < ApplicationController
  before_action :ensure_master_user_access, only: [:create]
  before_action :set_user, only: [:show, :update, :destroy, :unblock]

  def index
    users = User.includes(
      trainings: { training_exercises: [:exercise, :training_exercise_sets] },
      weekly_pdfs: [],
      meals: :comidas
    )
    
    render json: users.as_json(
      only: [:id, :name, :email, :registration_date, :plan_type, :plan_duration],
      include: {
        trainings: {
          only: [:id, :description, :weekday],
          include: {
            training_exercises: {
              only: [:id],
              include: {
                exercise: { only: [:id, :name, :video] },
                training_exercise_sets: { only: [:id, :series_amount, :repeats_amount] }
              }
            }
          }, 
        },
        weekly_pdfs: { only: [:id, :weekday, :pdf_url], methods: [:pdf_filename] },
        meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def show
    render json: @user.as_json(
      only: [:id, :name, :email, :registration_date, :plan_type, :plan_duration, :phone_number], 
      include: {
        trainings: {
          only: [:id, :description, :weekday],
          include: {
            training_exercises: {
              only: [:id],
              include: {
                exercise: { only: [:id, :name, :video] },
                training_exercise_sets: { only: [:id, :series_amount, :repeats_amount] }
              }
            }
          }, 
        },
        weekly_pdfs: { only: [:id, :weekday, :pdf_url], methods: [:pdf_filename] },
        meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end

  def current_user
    super
  end

  def create
    @user = User.new(user_params)
    
    # Process training_exercises to create exercises if necessary
    process_training_exercises(user_params[:trainings_attributes]) if user_params[:trainings_attributes].present?
    
    if @user.save
      render json: @user, status: :created
    else
      Rails.logger.error "Errors when saving: #{@user.errors.full_messages}"
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    attributes = user_params

    # Process training_exercises to create exercises if necessary
    process_training_exercises(attributes[:trainings_attributes]) if attributes[:trainings_attributes].present?

    # Handle training photos
    if attributes[:trainings_attributes].present?
      attributes[:trainings_attributes].each do |_, training_attrs|
        if training_attrs[:id].present?
          training = @user.trainings.find_by(id: training_attrs[:id])
          if training_attrs[:_destroy] == 'true'
            training&.photos&.each(&:purge)
          elsif training_attrs[:photos].present?
            training_attrs[:photos].each do |photo|
              training&.photos&.attach(photo)
            end
          end
        end
      end
    end

    # Handle user photo
    if attributes[:photo].present?
      @user.photo.purge if @user.photo.attached?
      @user.photo.attach(attributes[:photo])
    end

    if @user.update(attributes.except(:photo))
      render json: @user.as_json(
        only: [:id, :name, :email, :registration_date, :expiration_date, :plan_type, :plan_duration, :phone_number],
        methods: [:photo_url],
        include: {
          trainings: {
            only: [:id, :description, :weekday],
            include: {
              training_exercises: {
                only: [:id],
                include: {
                  exercise: { only: [:id, :name, :video] },
                  training_exercise_sets: { only: [:id, :series_amount, :repeats_amount] }
                }
              }
            },
          },
          weekly_pdfs: { only: [:id, :weekday, :pdf_url], methods: [:pdf_filename] },
          meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } }
        }
      ), status: :ok
    else
      Rails.logger.error "Errors when updating: #{@user.errors.full_messages}"
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @user.photo.purge if @user.photo.attached?
    @user.destroy
    render json: { message: 'User deleted successfully' }, status: :ok
  end

  def unblock
    @user.unblock_account!
    render json: { message: 'Account unblocked' }, status: :ok
  end

  def planilha
    user = User.find_by(api_key: params[:api_key])
    if user && !user.blocked
      if user.expired?
        user.block_account!
        render json: { error: 'Expired account. Contact the administrator.' }, status: :unauthorized
        return
      end

      response_data = {
        id: user.id,
        name: user.name,
        email: user.email,
        registration_date: user.registration_date,
        expiration_date: user.expiration_date,
        plan_type: user.plan_type,
        plan_duration: user.plan_duration,
        photo_url: user.photo.attached? ? url_for(user.photo) : nil,
        error: nil,
        trainings: user.trainings.as_json(
          only: [:id, :description, :weekday],
          include: {
            training_exercises: {
              only: [:id],
              include: {
                exercise: { only: [:id, :name, :video] },
                training_exercise_sets: { only: [:id, :series_amount, :repeats_amount] }
              }
            }
          }, 
        ),
        meals: user.meals.as_json(
          only: [:id, :meal_type, :weekday],
          include: { comidas: { only: [:id, :name, :amount] } }
        ),
        weekly_pdfs: user.weekly_pdfs.as_json(
          only: [:id, :weekday, :pdf_url],
          methods: [:pdf_filename]
        )
      }

      render json: response_data, status: :ok
    else
      render json: { error: 'Unauthorized access' }, status: :unauthorized
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def ensure_master_user_access
    unless current_user&.is_a?(MasterUser)
      render json: { error: 'Unauthorized access' }, status: :unauthorized
      return false
    end
    true
  end

  def process_training_exercises(trainings_attributes)
    return unless trainings_attributes.is_a?(Array) || trainings_attributes.is_a?(Hash)
    
    trainings_attributes.each do |key, training_attrs|
      training_attrs = training_attrs.is_a?(Hash) ? training_attrs : training_attrs
      next unless training_attrs[:training_exercises_attributes]
      
      training_attrs[:training_exercises_attributes].each do |ex_key, exercise_attrs|
        exercise_attrs = exercise_attrs.is_a?(Hash) ? exercise_attrs : exercise_attrs
        next if exercise_attrs[:_destroy] == 'true' || exercise_attrs[:_destroy] == true
        
        if exercise_attrs[:exercise_name].present?
          # Find or create exercise
          exercise = Exercise.find_or_create_by(
            name: exercise_attrs[:exercise_name]
          ) do |e|
            e.video = exercise_attrs[:video] if exercise_attrs[:video].present?
          end
          
          exercise_attrs[:exercise_id] = exercise.id
          # Remove exercise_name and video as they are not TrainingExercise model attributes
          exercise_attrs.delete(:exercise_name)
          exercise_attrs.delete(:video)
        end
      end
    end
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :password, :phone_number, :plan_type, :plan_duration, 
      :registration_date, :expiration_date, :photo,
      trainings_attributes: [
        :id, :weekday, :description, :_destroy,
        training_exercises_attributes: [
          :id, :exercise_id, :exercise_name, :video, :_destroy,
          training_exercise_sets_attributes: [
            :id, :series_amount, :repeats_amount, :_destroy
          ]
        ]
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
    master = MasterUser.first
    return unless master

    if master.device_token.present?
      message = {
        token: master.device_token,
        notification: {
          title: "Simultaneous Access Detected",
          body: "User #{user.email} tried to login from a new device."
        }
      }
      # Implement notification sending, e.g.: fcm.send([master.device_token], message)
    end
  end
end