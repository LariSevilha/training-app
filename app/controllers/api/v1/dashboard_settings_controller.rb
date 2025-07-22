module Api
  module V1
    class DashboardSettingsController < ApplicationController
      before_action :ensure_master, only: [:create, :update]
      before_action :set_dashboard_setting, only: [:show, :update]
      respond_to :json

      def index
        setting = DashboardSetting.first
        if setting
          Rails.logger.info "Generated logo_url: #{setting.logo_url}"
          render json: setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name], methods: [:logo_url]), status: :ok
        else
          render json: {
            id: nil,
            primary_color: '#000000',
            secondary_color: '#333333',
            tertiary_color: '#666666',
            app_name: '',
            logo_url: nil
          }, status: :ok
        end
      end

      def show
        Rails.logger.info "Generated logo_url: #{@dashboard_setting.logo_url}"
        render json: @dashboard_setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name], methods: [:logo_url]), status: :ok
      end

      def create
        dashboard_setting = DashboardSetting.new(dashboard_setting_params)
        if dashboard_setting.save
          if params[:dashboard_setting][:logo].present?
            dashboard_setting.logo.attach(params[:dashboard_setting][:logo])
          end
          Rails.logger.info "Created dashboard setting, logo_url: #{dashboard_setting.logo_url}"
          render json: dashboard_setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name], methods: [:logo_url]), status: :created
        else
          Rails.logger.error "Failed to create dashboard setting: #{dashboard_setting.errors.full_messages}"
          render json: { errors: dashboard_setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        Rails.logger.info "Updating dashboard setting with ID: #{params[:id]}"
        Rails.logger.info "Params: #{dashboard_setting_params}"
        if params[:dashboard_setting][:logo].present?
          @dashboard_setting.logo.purge if @dashboard_setting.logo.attached?
          @dashboard_setting.logo.attach(params[:dashboard_setting][:logo])
        end
        if @dashboard_setting.update(dashboard_setting_params)
          Rails.logger.info "Successfully updated dashboard setting, logo_url: #{@dashboard_setting.logo_url}"
          render json: @dashboard_setting.as_json(only: [:id, :primary_color, :secondary_color, :tertiary_color, :app_name], methods: [:logo_url]), status: :ok
        else
          Rails.logger.error "Failed to update dashboard setting: #{@dashboard_setting.errors.full_messages}"
          render json: { errors: @dashboard_setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_dashboard_setting
        @dashboard_setting = DashboardSetting.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Configuração não encontrada' }, status: :not_found
      end

      def dashboard_setting_params
        params.require(:dashboard_setting).permit(:primary_color, :secondary_color, :tertiary_color, :app_name, :logo)
      end

      def ensure_master
        render json: { error: 'Acesso não autorizado' }, status: :unauthorized unless current_user.is_a?(MasterUser)
      end
    end
  end
end