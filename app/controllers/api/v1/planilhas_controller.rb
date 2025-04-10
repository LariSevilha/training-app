module Api
    module V1
      class PlanilhasController < ApplicationController
        skip_before_action :verify_authenticity_token
  
        def show
          user = User.joins(:api_keys).find_by(api_keys: { token: extract_token, device_id: request.headers['Device-ID'], active: true })
          if user
            render json: {
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role,
              trainings: user.trainings || [],
              meals: user.meals || [],
              error: nil
            }, status: :ok
          else
            render json: { error: "Usuário não autorizado" }, status: :unauthorized
          end
        end
  
        private
  
        def extract_token
          request.headers['Authorization']&.split(' ')&.last
        end
      end
    end
  end