module Api
  module V1
    class SuperUsersController < ApplicationController
      before_action :authenticate_with_api_key
      before_action :ensure_super_user, except: [:create]
      before_action :ensure_super_user_or_initial_setup, only: [:create]
  
      def index
        begin
          super_users = SuperUser.all.includes(:api_keys)
          super_users_data = super_users.map do |super_user|
            {
              id: super_user.id,
              name: super_user.name,
              email: super_user.email,
              created_at: super_user.created_at,
              updated_at: super_user.updated_at,
              active_sessions: super_user.api_keys.active.count
            }
          end
          render json: super_users_data, status: :ok
        rescue StandardError => e
          Rails.logger.error "Error fetching super users: #{e.message}"
          render json: { error: "Erro ao buscar superusuários: #{e.message}" }, status: :internal_server_error
        end
      end

      def create
        super_user = SuperUser.new(super_user_params)
        begin
          if super_user.save
            device_id = params[:device_id] || SecureRandom.hex(8)
            api_key = super_user.api_keys.create!(
              device_id: device_id,
              token: SecureRandom.hex(16),
              active: true
            )
            render json: {
              message: 'Superusuário criado com sucesso',
              api_key: api_key.token,
              user_id: super_user.id,
              user_type: 'super'
            }, status: :created
          else
            render json: { errors: super_user.errors.full_messages }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Error creating super user: #{e.message}"
          render json: { errors: ["Erro ao criar superusuário: #{e.message}"] }, status: :unprocessable_entity
        end
      end

      def destroy
        begin
          if @super_user.id == current_user.id
            render json: { error: 'Não é possível excluir o próprio usuário' }, status: :unprocessable_entity
            return
          end
          @super_user.destroy!
          render json: { message: 'Superusuário excluído com sucesso' }, status: :ok
        rescue StandardError => e
          Rails.logger.error "Error deleting super user: #{e.message}"
          render json: { error: "Erro ao excluir superusuário: #{e.message}" }, status: :internal_server_error
        end
      end

      private

      def super_user_params
        params.require(:super_user).permit(:name, :email, :password, :password_confirmation)
      end

      def set_super_user
        @super_user = SuperUser.find_by(id: params[:id])
        unless @super_user
          Rails.logger.error "Super user not found for ID: #{params[:id]}"
          render json: { error: 'Superusuário não encontrado' }, status: :not_found
        end
      end

      def ensure_super_user
        unless current_user&.is_a?(SuperUser)
          Rails.logger.warn "Unauthorized access attempt by non-superuser: #{current_user&.id}"
          render json: { error: 'Acesso não autorizado. Apenas superusuários podem realizar esta ação.' }, status: :unauthorized
        end
      end
    end
  end
end