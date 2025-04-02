class Api::V1::UsersController < ApplicationController
  skip_before_action :authenticate_with_api_key, only: [:login]
  def index
    users = User.where(role: :regular).includes(trainings: [:serie, :repeat, :exercise], meals: :comidas)
    render json: users.as_json(
      include: {
        trainings: { include: [:serie, :repeat, :exercise], only: [:id] },
        meals: { include: :comidas, only: [:id, :meal_type] }
      }
    ), status: :ok
  end

  def create
    unless current_user&.role == 'master'
      render json: { error: 'Apenas o master pode criar usuários' }, status: :forbidden
      return
    end

    user_params = params.permit(user: [:email, :password]).require(:user)
    user = User.new(user_params)

    if user.save
      render json: { email: user.email }, status: :created
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

 def login
      user_params = params[:user] || {}
      email = user_params[:email]
      password = user_params[:password]
      device_id = user_params[:device_id]

      unless email && password && device_id
        render json: { error: 'Email, senha e device_id são obrigatórios' }, status: :bad_request
        return
      end

      user = User.find_by(email: email)
      unless user
        render json: { error: 'Credenciais inválidas' }, status: :unauthorized
        return
      end

      if user.authenticate(password) && !user.blocked
        existing_api_key = user.api_keys.active.find_by(device_id: device_id)
        if existing_api_key
          render json: { api_key: existing_api_key.token }, status: :ok
          return
        end

        if user.api_keys.active.exists? && user.api_keys.active.where.not(device_id: device_id).exists?
          notify_master_of_duplicate_login(user)
          user.block_account!
          render json: { error: 'Conta bloqueada devido a acesso simultâneo' }, status: :unauthorized
          return
        end

        api_key = user.api_keys.create!(device_id: device_id, token: SecureRandom.uuid)
        render json: { api_key: api_key.token }, status: :ok
      else
        render json: { error: 'Credenciais inválidas ou conta bloqueada' }, status: :unauthorized
      end
   end

  def unblock
    user = User.find(params[:id])
    if current_user&.role == 'master'
      user.unblock_account!
      render json: { message: 'Conta desbloqueada' }, status: :ok
    else
      render json: { error: 'Apenas o master pode desbloquear' }, status: :forbidden
    end
  end

  def update
    if @user.update(user_params.except(:trainings, :meals))
      # Atualizar treinos
      if user_params[:trainings].present?
        @user.trainings.destroy_all
        user_params[:trainings].each do |training_data|
          serie = Serie.create!(amount: training_data[:serie_amount])
          repeat = Repeat.create!(amount: training_data[:repeat_amount])
          exercise = Exercise.create!(name: training_data[:exercise_name], video: training_data[:video])
          @user.trainings.create!(serie: serie, repeat: repeat, exercise: exercise)
        end
      end

      # Atualizar dietas
      if user_params[:meals].present?
        @user.meals.destroy_all
        user_params[:meals].each do |meal_data|
          meal = @user.meals.create!(meal_type: meal_data[:meal_type])
          meal_data[:comidas].each do |comida_data|
            meal.comidas.create!(name: comida_data[:name], amount: comida_data[:amount])
          end
        end
      end

      render json: @user.as_json(
        include: {
          trainings: { include: [:serie, :repeat, :exercise], only: [:id] },
          meals: { include: :comidas, only: [:id, :meal_type] }
        }
      ), status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    render json: { message: 'Usuário deletado com sucesso' }, status: :ok
  end 
  def planilha
    user = User.find_by(api_key: params[:api_key])
    if user && user.role == 'regular' && !user.blocked
      render html: <<-HTML.html_safe
        <!DOCTYPE html>
        <html>
        <head>
          <title>Planilha</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            h1 { color: #333; }
            h2 { color: #555; }
            ul { list-style-type: none; padding: 0; }
            li { margin: 10px 0; }
          </style>
        </head>
        <body>
          <h1>Planilha de #{user.name}</h1>
          <h2>Treinos</h2>
          <ul>
            #{user.trainings.map { |t| "<li>#{t.exercise.name}: #{t.serie.amount} séries, #{t.repeat.amount} repetições</li>" }.join}
          </ul>
          <h2>Dietas</h2>
          <ul>
            #{user.meals.map { |m| "<li>#{m.meal_type}: #{m.comidas.map { |c| "#{c.name} (#{c.amount})" }.join(', ')}</li>" }.join}
          </ul>
        </body>
        </html>
      HTML
    else
      render json: { error: 'Acesso não autorizado' }, status: :unauthorized
    end
  end
  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :password,
      trainings: [:serie_amount, :repeat_amount, :exercise_name, :video],
      meals: [:meal_type, comidas: [:name, :amount]]
    )
  end

  def notify_master_of_duplicate_login(user)
    master = User.find_by(role: :master)  
    return unless master
  
    if master.device_token.present?
      message = {
        token: master.device_token,
        notification: {
          title: "Acesso Simultâneo Detectado",
          body: "O usuário #{user.email} tentou fazer login em um novo dispositivo."
        }
      }
      # Enviar a notificação (ex.: usando a gem 'fcm')
      # fcm = FCM.new("sua-chave-de-servidor-fcm")
      # fcm.send([master.device_token], message)
    end
  end
end