# app/controllers/api/v1/dashboard_controller.rb
module Api
  module V1
    class DashboardController < ApplicationController
      before_action :ensure_authorized_user

      def index
        begin
          user_data = build_user_data
          metrics_data = build_metrics_data
          
          render json: {
            user: user_data,
            metrics: metrics_data,
            message: 'Dashboard carregado com sucesso'
          }, status: :ok
        rescue StandardError => e
          Rails.logger.error "Dashboard error: #{e.message}"
          render json: { error: "Erro ao carregar dashboard: #{e.message}" }, status: :internal_server_error
        end
      end

      private

      def ensure_authorized_user
        unless current_user&.is_a?(MasterUser) || current_user&.is_a?(SuperUser)
          Rails.logger.warn "Unauthorized dashboard access by user: #{current_user&.class} - ID: #{current_user&.id}"
          render json: { error: 'Acesso não autorizado ao dashboard' }, status: :unauthorized
        end
      end

      def build_user_data
        {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          role: user_role,
          created_at: current_user.created_at,
          updated_at: current_user.updated_at
        }
      end

      def build_metrics_data
        case current_user
        when SuperUser
          build_super_user_metrics
        when MasterUser
          build_master_user_metrics
        else
          {}
        end
      end

      def build_super_user_metrics
        master_users = MasterUser.all
        total_masters = master_users.count
        total_users = User.count
        active_masters = master_users.joins(:api_keys).where(api_keys: { active: true }).distinct.count
        
        {
          total_masters: total_masters,
          total_users: total_users,
          active_masters: active_masters,
          total_api_keys: ApiKey.active.count,
          masters_with_users: master_users.joins(:users).distinct.count,
          recent_masters: master_users.where('created_at > ?', 30.days.ago).count
        }
      end

      def build_master_user_metrics
        users = current_user.users
        total_users = users.count
        active_users = users.joins(:api_keys).where(api_keys: { active: true }).distinct.count
      
        begin
          blocked_users = users.where(blocked: true).count
        rescue
          blocked_users = 0
        end
      
        {
          total_users: total_users,
          active_users: active_users,
          recent_users: users.where('created_at > ?', 30.days.ago).count,
          expiring_soon: users.where('expiration_date BETWEEN ? AND ?', Date.current, 7.days.from_now).count,
          plan_stats: users.group(:plan_type).count,
          duration_stats: users.group(:plan_duration).count,
          blocked_users: blocked_users,
          users_with_trainings: users.joins(:trainings).distinct.count,
          users_with_meals: users.joins(:meals).distinct.count
        }
      end
      
      def user_role
        case current_user
        when SuperUser
          'super'
        when MasterUser
          'master'
        else
          'user'
        end
      end
    end
  end
end
