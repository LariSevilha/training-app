module Api
  module V1
    class DashboardController < ApplicationController
      before_action :ensure_master, only: [:index]
      respond_to :json

      def index
        Rails.logger.info("Carregando dashboard para usuário: #{current_user.id}, role: #{current_user.role}")
        render json: current_user.as_json(
          only: [:id, :name, :email, :role],
          include: {
            trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :weekday] },
            meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } },
            weekly_pdfs: { only: [:id, :weekday, :pdf_url], methods: [:pdf_filename] }
          }
        ), status: :ok
      rescue StandardError => e
        Rails.logger.error("Erro ao carregar dashboard: #{e.message}\nBacktrace: #{e.backtrace.join("\n")}")
        render json: { error: "Erro ao carregar o dashboard: #{e.message}" }, status: :internal_server_error
      end

      private

      def ensure_master
        unless current_user&.role == 'master'
          Rails.logger.warn("Acesso não autorizado ao dashboard: usuário #{current_user&.id}")
          render json: { error: 'Acesso não autorizado' }, status: :unauthorized
        end
      end
    end
  end
end

