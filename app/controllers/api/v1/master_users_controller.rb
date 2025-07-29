module Api
  module V1
    class MasterUsersController < ApplicationController
      before_action :ensure_super_user, only: [:create, :index, :destroy]
      before_action :ensure_master_or_super, only: [:show, :update, :current_master]
      before_action :set_master_user, only: [:show, :update, :destroy]

      def index
        begin
          master_users = MasterUser.all.includes(:api_keys, :users)
          
          masters_data = master_users.map do |master|
            {
              id: master.id,
              name: master.name,
              email: master.email,
              phone_number: master.phone_number,
              cpf: master.cpf,
              cref: master.cref,
              created_at: master.created_at,
              updated_at: master.updated_at,
              users_count: master.users.count,
              active_sessions: master.api_keys.active.count,
              photo_url: master.photo_url,
              role: 'master'
            }
          end
          
          render json: masters_data, status: :ok
        rescue StandardError => e
          Rails.logger.error "Error fetching master users: #{e.message}"
          render json: { error: "Erro ao buscar usuários master: #{e.message}" }, status: :internal_server_error
        end
      end

      # Nova action para buscar o master user atual
      def current_master
        begin
          if current_user.is_a?(MasterUser)
            render json: current_user.as_json(
              only: [:id, :name, :email, :phone_number, :cpf, :cref, :created_at, :updated_at],
              methods: [:photo_url]
            ).merge(role: 'master'), status: :ok
          elsif current_user.is_a?(SuperUser)
            # SuperUser pode acessar dados básicos
            render json: {
              id: current_user.id,
              name: current_user.name,
              email: current_user.email,
              role: 'super'
            }, status: :ok
          else
            render json: { error: 'Usuário não autorizado' }, status: :unauthorized
          end
        rescue StandardError => e
          Rails.logger.error "Error fetching current master: #{e.message}"
          render json: { error: "Erro ao buscar dados do usuário: #{e.message}" }, status: :internal_server_error
        end
      end

      def create
        master_user = MasterUser.new(master_user_params)
        if master_user.save
          render json: {
            id: master_user.id,
            name: master_user.name,
            email: master_user.email,
            phone_number: master_user.phone_number,
            cpf: master_user.cpf,
            cref: master_user.cref,
            photo_url: master_user.photo_url,
            role: 'master',
            message: 'Master user criado com sucesso'
          }, status: :created
        else
          render json: { errors: master_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        begin
          Rails.logger.info "Generated photo_url: #{@master_user.photo_url}"
          render json: @master_user.as_json(
            only: [:id, :name, :email, :phone_number, :cpf, :cref, :created_at, :updated_at],
            methods: [:photo_url]
          ).merge(role: 'master'), status: :ok
        rescue StandardError => e
          Rails.logger.error "Error in show action: #{e.message}"
          render json: { error: "Erro ao buscar usuário master: #{e.message}" }, status: :internal_server_error
        end
      end

      def update
        Rails.logger.info "Updating master user with params: #{params[:master_user].inspect}"
        begin
          ActiveRecord::Base.transaction do
            if params[:master_user][:photo].present? && params[:master_user][:photo].respond_to?(:content_type)
              Rails.logger.info "Purging existing photo for master user ID: #{@master_user.id}"
              @master_user.photo.purge_later if @master_user.photo.attached?
              Rails.logger.info "Attaching new photo: #{params[:master_user][:photo].original_filename}"
              @master_user.photo.attach(params[:master_user][:photo])
              unless @master_user.photo.attached?
                raise ActiveRecord::RecordInvalid.new(@master_user), "Falha ao anexar a nova foto"
              end
            end

            if @master_user.update(master_user_params.except(:photo))
              Rails.logger.info "Master user updated successfully, photo_url: #{@master_user.photo_url}"
              render json: @master_user.as_json(
                only: [:id, :name, :email, :phone_number, :cpf, :cref, :created_at, :updated_at],
                methods: [:photo_url]
              ).merge(role: 'master'), status: :ok
            else
              Rails.logger.error "Failed to update master user: #{@master_user.errors.full_messages}"
              render json: { errors: @master_user.errors.full_messages }, status: :unprocessable_entity
            end
          end
        rescue => e
          Rails.logger.error "Error updating master user: #{e.message}"
          render json: { errors: ["Erro ao atualizar usuário master: #{e.message}"] }, status: :unprocessable_entity
        end
      end

      def destroy
        begin
          if @master_user.users.any?
            render json: { error: 'Não é possível excluir um master user que possui usuários cadastrados' }, status: :unprocessable_entity
            return
          end

          @master_user.destroy!
          render json: { message: 'Master user excluído com sucesso' }, status: :ok
        rescue StandardError => e
          Rails.logger.error "Error deleting master user: #{e.message}"
          render json: { error: "Erro ao excluir usuário master: #{e.message}" }, status: :internal_server_error
        end
      end

      private

      def set_master_user
        if current_user.is_a?(SuperUser)
          # SuperUser pode acessar qualquer master user
          @master_user = MasterUser.find_by(id: params[:id]) if params[:id].present?
          @master_user ||= MasterUser.find(params[:id]) if params[:id].present?
        else
          # MasterUser só pode acessar seus próprios dados
          @master_user = current_user if current_user.is_a?(MasterUser)
        end
        
        unless @master_user
          Rails.logger.error "Master user not found for current_user: #{current_user&.id}, params[:id]: #{params[:id]}"
          render json: { error: 'Usuário master não encontrado' }, status: :not_found and return
        end
      end

      def master_user_params
        params.require(:master_user).permit(:name, :email, :phone_number, :cpf, :cref, :photo, :password, :password_confirmation)
      end
      
      def ensure_master_or_super
        unless current_user.is_a?(MasterUser) || current_user.is_a?(SuperUser)
          Rails.logger.warn "Unauthorized access attempt by user: #{current_user&.id}"
          render json: { error: 'Acesso não autorizado' }, status: :unauthorized and return
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