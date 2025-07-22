module Api
  module V1
    class PlanilhasController < ApplicationController
      before_action :authenticate_with_api_key
      before_action :ensure_regular_user

      def show
        user = current_user # Usar current_user do ApplicationController
        Rails.logger.info("Carregando planilha para usuário: #{user.id}, nome: #{user.name || user.email}")
        
        trainings_data = user.trainings.map do |training|
          {
            exercise_name: training.exercise_name,
            serie_amount: training.serie_amount&.to_i || 0,
            repeat_amount: training.repeat_amount&.to_i || 0,
            video: training.video,
            weekday: training.weekday,
            photo_urls: training.photo_urls
          }
        end
        
        meals_data = user.meals.map do |meal|
          {
            meal_type: meal.meal_type,
            weekday: meal.weekday,
            comidas: meal.comidas.map { |c| { id: c.id, name: c.name, amount: c.amount } }
          }
        end
        
        weekly_pdfs_data = user.weekly_pdfs.map do |pdf|
          {
            id: pdf.id,
            weekday: pdf.weekday,
            pdf_url: pdf.pdf_url,
            pdf_filename: pdf.pdf_filename
          }
        end

        render json: {
          name: user.name || user.email,
          trainings: trainings_data,
          meals: meals_data,
          weekly_pdfs: weekly_pdfs_data,
          error: nil
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error("Erro ao carregar planilha: #{e.message}\nBacktrace: #{e.backtrace.join("\n")}")
        render json: { error: "Erro ao carregar a planilha: #{e.message}" }, status: :internal_server_error
      end

      private

      def ensure_regular_user
        unless current_user&.is_a?(User)
          render json: { error: 'Apenas usuários regulares podem acessar esta ação' }, status: :forbidden
        end
      end
    end
  end
end