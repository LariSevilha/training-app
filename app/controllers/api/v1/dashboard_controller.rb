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

      def current_user_profile
        begin
          user = current_user
          
          unless user
            Rails.logger.error "No authenticated user found in current_user_profile"
            render json: { error: 'Usuário não autenticado' }, status: :unauthorized
            return
          end

          Rails.logger.info "Fetching profile for user: #{user.class} - ID: #{user.id}"
          
          # Build detailed user data based on user type
          user_data = build_detailed_user_data_for_profile
          
          Rails.logger.info "Profile data built successfully for user ID: #{user.id}"
          
          render json: user_data, status: :ok
          
        rescue StandardError => e
          Rails.logger.error "Error in current_user_profile: #{e.message}"
          Rails.logger.error "Backtrace: #{e.backtrace.join('\n')}"
          render json: { 
            error: "Erro ao carregar perfil: #{e.message}",
            details: Rails.env.development? ? e.backtrace.first(5) : nil
          }, status: :internal_server_error
        end
      end

      def update_current_user
        begin
          ActiveRecord::Base.transaction do
            user = current_user
            unless user
              render json: { error: 'Usuário não autenticado' }, status: :unauthorized
              return
            end

            Rails.logger.info "Updating profile for user ID: #{user.id}, type: #{user.class}"

            # Handle photo upload if present
            if user_params[:photo].present? && user_params[:photo].respond_to?(:content_type)
              Rails.logger.info "Updating photo for user ID: #{user.id}"
              user.photo.purge_later if user.photo.attached?
              user.photo.attach(user_params[:photo])
              unless user.photo.attached?
                raise ActiveRecord::RecordInvalid.new(user), "Falha ao anexar a nova foto"
              end
            end

            # Update user data
            update_params = user_params.except(:photo)
            Rails.logger.info "Update params: #{update_params.inspect}"
            
            if user.update(update_params)
              Rails.logger.info "User updated successfully"
              updated_user_data = build_detailed_user_data_for_profile
              
              render json: {
                user: updated_user_data,
                message: 'Perfil atualizado com sucesso'
              }, status: :ok
            else
              Rails.logger.error "Failed to update user: #{user.errors.full_messages}"
              render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
            end
          end
        rescue StandardError => e
          Rails.logger.error "Error updating current user: #{e.message}"
          render json: { errors: ["Erro ao atualizar perfil: #{e.message}"] }, status: :unprocessable_entity
        end
      end

      def change_password
        begin
          user = current_user
          unless user
            render json: { errors: ['Usuário não autenticado'] }, status: :unauthorized
            return
          end

          current_password = params[:current_password]
          new_password = params[:new_password]
          new_password_confirmation = params[:new_password_confirmation]

          # Validate required parameters
          if current_password.blank?
            render json: { errors: ['Senha atual é obrigatória'] }, status: :unprocessable_entity
            return
          end

          if new_password.blank?
            render json: { errors: ['Nova senha é obrigatória'] }, status: :unprocessable_entity
            return
          end

          # Validate current password
          unless user.authenticate(current_password)
            render json: { errors: ['Senha atual incorreta'] }, status: :unprocessable_entity
            return
          end

          # Validate new password
          if new_password != new_password_confirmation
            render json: { errors: ['Nova senha e confirmação não coincidem'] }, status: :unprocessable_entity
            return
          end

          if new_password.length < 6
            render json: { errors: ['Nova senha deve ter pelo menos 6 caracteres'] }, status: :unprocessable_entity
            return
          end

          # Update password
          if user.update(password: new_password, password_confirmation: new_password_confirmation)
            Rails.logger.info "Password changed successfully for user ID: #{user.id}"
            render json: { message: 'Senha alterada com sucesso' }, status: :ok
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error "Error changing password: #{e.message}"
          render json: { errors: ["Erro ao alterar senha: #{e.message}"] }, status: :internal_server_error
        end
      end

      private

      # CORREÇÃO: Permitir acesso tanto para SuperUser quanto MasterUser
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

      def build_detailed_user_data_for_profile
        begin
          base_data = {
            id: current_user.id,
            name: current_user.name,
            email: current_user.email,
            role: user_role,
            created_at: current_user.created_at.iso8601,
            updated_at: current_user.updated_at.iso8601
          }

          # Add specific fields based on user type
          case current_user
          when MasterUser
            Rails.logger.info "Building profile data for MasterUser"
            photo_url = nil
            begin
              photo_url = current_user.photo_url if current_user.respond_to?(:photo_url)
            rescue => photo_error
              Rails.logger.warn "Error getting photo URL for MasterUser: #{photo_error.message}"
            end

            base_data.merge({
              phone_number: current_user.phone_number,
              cpf: current_user.cpf,
              cref: current_user.cref,
              photo_url: photo_url
            })
          when SuperUser
            Rails.logger.info "Building profile data for SuperUser"
            photo_url = nil
            begin
              photo_url = current_user.photo_url if current_user.respond_to?(:photo_url)
            rescue => photo_error
              Rails.logger.warn "Error getting photo URL for SuperUser: #{photo_error.message}"
            end

            base_data.merge({
              phone_number: current_user.respond_to?(:phone_number) ? current_user.phone_number : nil,
              photo_url: photo_url
            })
          else
            Rails.logger.warn "Unknown user type: #{current_user.class}"
            base_data
          end
        rescue => e
          Rails.logger.error "Error in build_detailed_user_data_for_profile: #{e.message}"
          # Return basic data if detailed build fails
          {
            id: current_user.id,
            name: current_user.name,
            email: current_user.email,
            role: user_role,
            created_at: current_user.created_at.iso8601,
            updated_at: current_user.updated_at.iso8601,
            phone_number: nil,
            cpf: nil,
            cref: nil,
            photo_url: nil
          }
        end
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

      # CORREÇÃO: Ajustar user_params para SuperUser
      def user_params
        case current_user
        when MasterUser
          params.require(:user).permit(:name, :email, :phone_number, :cpf, :cref, :photo, :password, :password_confirmation)
        when SuperUser  
          # SuperUser pode ter phone_number mas não CPF/CREF
          params.require(:user).permit(:name, :email, :phone_number, :photo, :password, :password_confirmation)
        else
          params.require(:user).permit(:name, :email, :phone_number, :password, :password_confirmation)
        end
      end
    end
  end
end