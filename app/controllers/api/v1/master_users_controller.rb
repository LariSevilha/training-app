# app/controllers/api/v1/master_users_controller.rb
module Api
  module V1
    class MasterUsersController < ApplicationController
      before_action :ensure_super_user
      before_action :set_master_user, only: [:show, :update, :destroy]

      # GET /api/v1/master_users
      def index
        begin
          master_users = MasterUser.all.order(:name)
          render json: master_users.map { |mu| MasterUserSerializer.new(mu).as_json }, status: :ok
        rescue StandardError => e
          Rails.logger.error "Error listing master users: #{e.message}"
          render json: { error: "Erro ao listar master users: #{e.message}" }, status: :internal_server_error
        end
      end

      # GET /api/v1/master_users/:id
      def show
        begin
          render json: MasterUserSerializer.new(@master_user).as_json, status: :ok
        rescue StandardError => e
          Rails.logger.error "Error showing master user: #{e.message}"
          render json: { error: "Erro ao carregar master user: #{e.message}" }, status: :internal_server_error
        end
      end

      # POST /api/v1/master_users
      def create
        begin
          master_user = MasterUser.new(master_user_params)
          
          if master_user.save
            # Criar API key para o novo master user
            device_id = params[:device_id] || SecureRandom.hex(8)
            api_key = master_user.api_keys.create!(
              device_id: device_id,
              token: SecureRandom.hex(16),
              active: true
            )

            Rails.logger.info "Master user created successfully: #{master_user.id}"
            
            render json: {
              message: 'Master user criado com sucesso',
              master_user: MasterUserSerializer.new(master_user).as_json,
              api_key: api_key.token
            }, status: :created
          else
            Rails.logger.error "Failed to create master user: #{master_user.errors.full_messages}"
            render json: { errors: master_user.errors.full_messages }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Error creating master user: #{e.message}"
          render json: { errors: ["Erro ao criar master user: #{e.message}"] }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/v1/master_users/:id
      def update
        begin
          ActiveRecord::Base.transaction do
            # Handle photo upload if present
            if master_user_params[:photo].present? && master_user_params[:photo].respond_to?(:content_type)
              Rails.logger.info "Updating photo for master user ID: #{@master_user.id}"
              @master_user.photo.purge_later if @master_user.photo.attached?
              @master_user.photo.attach(master_user_params[:photo])
            end

            # Update master user data
            update_params = master_user_params.except(:photo)
            
            if @master_user.update(update_params)
              Rails.logger.info "Master user updated successfully: #{@master_user.id}"
              render json: {
                message: 'Master user atualizado com sucesso',
                master_user: MasterUserSerializer.new(@master_user).as_json
              }, status: :ok
            else
              Rails.logger.error "Failed to update master user: #{@master_user.errors.full_messages}"
              render json: { errors: @master_user.errors.full_messages }, status: :unprocessable_entity
            end
          end
        rescue StandardError => e
          Rails.logger.error "Error updating master user: #{e.message}"
          render json: { errors: ["Erro ao atualizar master user: #{e.message}"] }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/master_users/:id
      def destroy
        begin
          ActiveRecord::Base.transaction do
            # Verificar se o master user tem usuários associados
            if @master_user.users.exists?
              render json: { 
                error: 'Não é possível excluir este master user pois ele possui usuários associados.' 
              }, status: :unprocessable_entity
              return
            end

            @master_user.destroy!
            Rails.logger.info "Master user deleted successfully: #{@master_user.id}"
            render json: { message: 'Master user excluído com sucesso' }, status: :ok
          end
        rescue StandardError => e
          Rails.logger.error "Error deleting master user: #{e.message}"
          render json: { error: "Erro ao excluir master user: #{e.message}" }, status: :internal_server_error
        end
      end

      private

      def ensure_super_user
        unless current_user&.is_a?(SuperUser)
          Rails.logger.warn "Unauthorized master users access by user: #{current_user&.class} - ID: #{current_user&.id}"
          render json: { error: 'Acesso não autorizado. Apenas superusuários podem gerenciar master users.' }, status: :unauthorized
        end
      end

      def set_master_user
        @master_user = MasterUser.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        Rails.logger.error "Master user not found: #{params[:id]}"
        render json: { error: 'Master user não encontrado' }, status: :not_found
      end

      def master_user_params
        params.require(:master_user).permit(
          :name, :email, :password, :password_confirmation, 
          :phone_number, :cpf, :cref, :photo
        )
      end
    end
  end
end