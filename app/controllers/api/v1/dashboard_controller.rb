class Api::V1::DashboardController < ApplicationController
  before_action :ensure_master, only: [:index] # Opcional, se o dashboard for restrito ao master
  respond_to :json

  def index
    user = current_user
    render json: user.as_json(
      only: [:id, :name, :email, :role],
      include: {
        trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video] },
        meals: { only: [:id, :meal_type], include: { comidas: { only: [:id, :name, :amount] } } }
      }
    ), status: :ok
  end
end