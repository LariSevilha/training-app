module Api
  module V1
    class SuperUsersController < ApplicationController
      before_action :authenticate_with_api_key
      before_action :ensure_super_user, except: [:create]
      before_action :ensure_super_user_or_initial_setup, only: [:create]

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

      private

      def ensure_super_user_or_initial_setup
        return if SuperUser.count.zero? # Allow initial superuser creation
        unless current_user&.is_a?(SuperUser)
          Rails.logger.warn "Unauthorized access attempt by non-superuser: #{current_user&.id}"
          render json: { error: 'Acesso não autorizado. Apenas superusuários podem criar outros superusuários.' }, status: :unauthorized
        end
      end

      def super_user_params
        params.require(:super_user).permit(:name, :email, :password, :password_confirmation)
      end
    end
  end
end