class Api::V1::AuthenticationController < ApplicationController
    def login
      user = User.find_by(email: params[:email])
      
      if user && user.authenticate(params[:password])
        token = generate_token(user.id)
        render json: { token: token, user: user }
      else
        render json: { error: 'Credenciais inválidas' }, status: :unauthorized
      end
    end
    
    def register
      user = User.new(user_params)
      
      if user.save
        token = generate_token(user.id)
        render json: { token: token, user: user }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def logout
      # Implementar lógica de logout se estiver usando tokens ou sessões
      render json: { message: 'Logout realizado com sucesso' }
    end
    
    private
    
    def user_params
      params.require(:user).permit(:name, :email, :password, :permission_id, :user_type_id, :avatar)
    end
    
    def generate_token(user_id)
      # Implementar geração de JWT ou outro tipo de token
      # Exemplo simplificado
      "user_#{user_id}_token_#{Time.now.to_i}"
    end
end