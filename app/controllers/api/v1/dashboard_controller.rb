module Api
  module V1
    class DashboardController < ApplicationController
      before_action :authorize_master!, if: -> { params[:user_id].present? }

      def index
        user = params[:user_id] ? User.find(params[:user_id]) : current_user
        render json: user, serializer: UserSerializer
      end

      private

      def authorize_master!
        render json: { error: 'Acesso negado' }, status: :forbidden unless current_user.role == 'master'
      end
    end
  end
end