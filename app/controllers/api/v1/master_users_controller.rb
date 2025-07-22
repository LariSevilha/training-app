module Api
  module V1
    class MasterUsersController < ApplicationController
      before_action :ensure_master, only: [:show, :update]
      before_action :set_master_user, only: [:show, :update]

      def show
        Rails.logger.info "Generated photo_url: #{@master_user.photo_url}"
        render json: @master_user.as_json(
          only: [:id, :name, :email, :phone_number, :cpf, :cref],
          methods: [:photo_url]
        ), status: :ok
      rescue StandardError => e
        Rails.logger.error "Error in show action: #{e.message}"
        render json: { error: "Erro ao buscar usuário master: #{e.message}" }, status: :internal_server_error
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
                only: [:id, :name, :email, :phone_number, :cpf, :cref],
                methods: [:photo_url]
              ), status: :ok
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

      private

      def set_master_user
        @master_user = current_user if current_user.is_a?(MasterUser)
        @master_user ||= MasterUser.find_by(id: params[:id]) if params[:id].present?
        unless @master_user
          Rails.logger.error "Master user not found for current_user: #{current_user&.id}, params[:id]: #{params[:id]}"
          render json: { error: 'Usuário master não encontrado' }, status: :not_found and return
        end
      end

      def master_user_params
        params.require(:master_user).permit(:name, :email, :phone_number, :cpf, :cref, :photo, :password)
      end

      def ensure_master
        unless current_user.is_a?(MasterUser)
          Rails.logger.warn "Unauthorized access attempt by user: #{current_user&.id}"
          render json: { error: 'Acesso não autorizado' }, status: :unauthorized and return
        end
      end
    end
  end
end