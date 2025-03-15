class Api::V1::DashboardController < ApplicationController
    def index
      user_id = params[:user_id]
      
      recent_trainings = Training.where(user_id: user_id).order(created_at: :desc).limit(5)
      recent_meals = Meal.joins(:comidas)
                        .joins("INNER JOIN foods ON foods.comida_id = comidas.id")
                        .where(user_id: user_id)
                        .distinct
                        .order(created_at: :desc)
                        .limit(5)
      
      dashboard_data = {
        recent_trainings: recent_trainings,
        recent_meals: recent_meals,
        training_count: Training.where(user_id: user_id).count,
        exercise_count: Training.where(user_id: user_id).select(:exercise_id).distinct.count
      }
      
      render json: dashboard_data
    end
  end