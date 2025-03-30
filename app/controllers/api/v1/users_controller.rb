# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  before_action :authenticate_with_api_key
  before_action :ensure_master, except: [:index]
  before_action :set_user, only: [:update, :destroy]

  def index
    users = User.where(role: :regular).includes(trainings: [:serie, :repeat, :exercise], meals: :comidas)
    render json: users.as_json(
      include: {
        trainings: { include: [:serie, :repeat, :exercise], only: [:id] },
        meals: { include: :comidas, only: [:id, :meal_type] }
      }
    ), status: :ok
  end

  def create
    user = User.new(user_params.except(:trainings, :meals))
    user.role = :regular

    if user.save
      # Criar treinos
      if user_params[:trainings].present?
        user_params[:trainings].each do |training_data|
          serie = Serie.create!(amount: training_data[:serie_amount])
          repeat = Repeat.create!(amount: training_data[:repeat_amount])
          exercise = Exercise.create!(name: training_data[:exercise_name], video: training_data[:video])
          user.trainings.create!(serie: serie, repeat: repeat, exercise: exercise)
        end
      end

      # Criar dietas
      if user_params[:meals].present?
        user_params[:meals].each do |meal_data|
          meal = user.meals.create!(meal_type: meal_data[:meal_type])
          meal_data[:comidas].each do |comida_data|
            meal.comidas.create!(name: comida_data[:name], amount: comida_data[:amount])
          end
        end
      end

      render json: user.as_json(
        include: {
          trainings: { include: [:serie, :repeat, :exercise], only: [:id] },
          meals: { include: :comidas, only: [:id, :meal_type] }
        }
      ), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params.except(:trainings, :meals))
      # Atualizar treinos
      if user_params[:trainings].present?
        @user.trainings.destroy_all
        user_params[:trainings].each do |training_data|
          serie = Serie.create!(amount: training_data[:serie_amount])
          repeat = Repeat.create!(amount: training_data[:repeat_amount])
          exercise = Exercise.create!(name: training_data[:exercise_name], video: training_data[:video])
          @user.trainings.create!(serie: serie, repeat: repeat, exercise: exercise)
        end
      end

      # Atualizar dietas
      if user_params[:meals].present?
        @user.meals.destroy_all
        user_params[:meals].each do |meal_data|
          meal = @user.meals.create!(meal_type: meal_data[:meal_type])
          meal_data[:comidas].each do |comida_data|
            meal.comidas.create!(name: comida_data[:name], amount: comida_data[:amount])
          end
        end
      end

      render json: @user.as_json(
        include: {
          trainings: { include: [:serie, :repeat, :exercise], only: [:id] },
          meals: { include: :comidas, only: [:id, :meal_type] }
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

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :password,
      trainings: [:serie_amount, :repeat_amount, :exercise_name, :video],
      meals: [:meal_type, comidas: [:name, :amount]]
    )
  end
end