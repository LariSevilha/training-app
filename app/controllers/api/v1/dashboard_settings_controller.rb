module Api
  module V1
    class DashboardSettingsController < ApplicationController
      before_action :ensure_authorized_user # Permitir tanto MasterUser quanto SuperUser
      before_action :set_dashboard_setting, only: [:show, :update]
      respond_to :json

      def index
        setting = get_user_setting
        if setting
          logo_url = generate_logo_url(setting)
          Rails.logger.info "Generated logo_url: #{logo_url}"
          render json: setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name]).merge(logo_url: logo_url), status: :ok
        else
          render json: default_settings, status: :ok
        end
      end

      def show
        logo_url = generate_logo_url(@dashboard_setting)
        Rails.logger.info "Generated logo_url: #{logo_url}"
        render json: @dashboard_setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name]).merge(logo_url: logo_url), status: :ok
      end

      def create
        setting_params = dashboard_setting_params
        
        # Se for MasterUser, associar a configuração a ele
        if current_user.is_a?(MasterUser)
          setting_params[:master_user_id] = current_user.id
        end
        # Se for SuperUser, criar configuração global (master_user_id = nil)
        
        dashboard_setting = DashboardSetting.new(setting_params)
        
        if dashboard_setting.save
          logo_url = generate_logo_url(dashboard_setting)
          Rails.logger.info "Created dashboard setting, logo_url: #{logo_url}"
          render json: dashboard_setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name]).merge(logo_url: logo_url), status: :created
        else
          Rails.logger.error "Failed to create dashboard setting: #{dashboard_setting.errors.full_messages}"
          render json: { errors: dashboard_setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        Rails.logger.info "Updating dashboard setting with ID: #{params[:id]}"
        Rails.logger.info "Params: #{dashboard_setting_params}"
        
        # Verificar se o usuário tem permissão para editar esta configuração
        unless can_edit_setting?(@dashboard_setting)
          render json: { error: 'Não autorizado a editar esta configuração' }, status: :forbidden
          return
        end
        
        # Remove logo antiga se uma nova for enviada
        if params[:dashboard_setting][:logo].present? && @dashboard_setting.logo.attached?
          @dashboard_setting.logo.purge
        end
        
        if @dashboard_setting.update(dashboard_setting_params)
          logo_url = generate_logo_url(@dashboard_setting)
          Rails.logger.info "Successfully updated dashboard setting, logo_url: #{logo_url}"
          render json: @dashboard_setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name]).merge(logo_url: logo_url), status: :ok
        else
          Rails.logger.error "Failed to update dashboard setting: #{@dashboard_setting.errors.full_messages}"
          render json: { errors: @dashboard_setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_dashboard_setting
        @dashboard_setting = find_user_setting_by_id(params[:id])
        unless @dashboard_setting
          render json: { error: 'Configuração não encontrada' }, status: :not_found
        end
      end

      def get_user_setting
        DashboardSetting.for_user(current_user)
      end
      
      def find_user_setting_by_id(id)
        case current_user
        when MasterUser
          # MasterUser só pode acessar sua própria configuração
          current_user.dashboard_setting if current_user.dashboard_setting&.id == id.to_i
        when SuperUser
          # SuperUser pode acessar configuração global
          setting = DashboardSetting.find_by(id: id)
          setting if setting&.master_user_id.nil? # Só configurações globais
        else
          nil
        end
      end
      
      def can_edit_setting?(setting)
        case current_user
        when MasterUser
          # MasterUser só pode editar sua própria configuração
          setting.master_user_id == current_user.id
        when SuperUser
          # SuperUser só pode editar configurações globais
          setting.master_user_id.nil?
        else
          false
        end
      end

      def dashboard_setting_params
        params.require(:dashboard_setting).permit(:primary_color, :secondary_color, :tertiary_color, :app_name, :logo)
      end

      def ensure_authorized_user
        unless current_user&.is_a?(MasterUser) || current_user&.is_a?(SuperUser)
          render json: { error: 'Acesso não autorizado' }, status: :unauthorized
        end
      end
      
      def default_settings
        {
          id: nil,
          primary_color: '#000000',
          secondary_color: '#333333',
          tertiary_color: '#666666',
          app_name: 'Dashboard',
          logo_url: nil
        }
      end

      def generate_logo_url(setting)
        return nil unless setting&.logo&.attached?
        
        begin
          if Rails.env.development?
            Rails.application.routes.url_helpers.rails_blob_url(setting.logo, host: 'localhost:3000', protocol: 'http')
          else
            Rails.application.routes.url_helpers.rails_blob_url(setting.logo, host: Rails.application.config.action_mailer.default_url_options[:host] || request.host, protocol: request.protocol.chomp('://'))
          end
        rescue => e
          Rails.logger.error "Error generating logo URL: #{e.message}"
          Rails.application.routes.url_helpers.rails_blob_path(setting.logo)
        end
      end
    end
  end
end