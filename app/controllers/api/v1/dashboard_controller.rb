module Api
  module V1
    class DashboardController < ApplicationController
      before_action :authenticate_with_api_key
      before_action :ensure_master_user

      def index
        dashboard_data = {
          user: current_user.as_json(only: [:id, :name, :email]),
          metrics: {
            total_users: User.count,
            active_users: User.count,
            total_master_users: MasterUser.count
          }
        }

        render json: dashboard_data, status: :ok
      rescue StandardError => e
        Rails.logger.error("Erro ao carregar dashboard: #{e.message}")
        render json: { error: 'Erro ao carregar o dashboard' }, status: :internal_server_error
      end

      private

      def ensure_master_user
        unless current_user&.is_a?(MasterUser)
          render json: { error: 'Acesso não autorizado. Apenas usuários master podem acessar o dashboard.' }, status: :unauthorized
        end
      end
    end
  end
end