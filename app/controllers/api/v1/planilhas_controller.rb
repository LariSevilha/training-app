module Api
  module V1
    class PlanilhasController < ApplicationController
      before_action :authenticate_with_api_key

      def show
        user = @current_user
        render json: {
          name: user.name || user.email,
          trainings: user.trainings.map do |training|
            {
              exercise_name: training.exercise_name,
              serie_amount: training.serie_amount.to_i,
              repeat_amount: training.repeat_amount.to_i,
              video: training.video,
              weekday: training.weekday
            }
          end,
          meals: user.meals.map do |meal|
            {
              meal_type: meal.meal_type,
              weekday: meal.weekday,
              comidas: meal.comidas
            }
          end
          error: nil
        }, status: :ok
      rescue StandardError => e
        render json: { error: "Erro ao carregar a planilha: #{e.message}" }, status: :internal_server_error
      end

      private

      def authenticate_with_api_key
        api_key = request.headers['Authorization']&.split(' ')&.last
        device_id = request.headers['Device-ID']
        unless api_key && device_id
          render json: { error: 'API key e device_id são obrigatórios' }, status: :unauthorized
          return
        end
        @current_api_key = ApiKey.active.find_by(token: api_key, device_id: device_id)
        unless @current_api_key
          render json: { error: 'API key inválida ou inativa' }, status: :unauthorized
          return
        end
        @current_user = @current_api_key.user
      end
    end
  end
end