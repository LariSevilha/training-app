module Api
    module V1
      class DashboardController < ApplicationController
        before_action :authenticate_user!
        before_action :authorize_master!
  
        def index
          users = User.where(role: :regular)
          render json: users, status: :ok
        end
  
        private
  
        def authorize_master!
          render json: { error: 'Acesso negado' }, status: :forbidden unless current_user.master?
        end
      end
    end
  end