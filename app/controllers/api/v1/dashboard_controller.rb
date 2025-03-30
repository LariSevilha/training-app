# app/controllers/api/v1/dashboard_controller.rb
class Api::V1::DashboardController < ApplicationController
  before_action :ensure_master, only: :index

  def index
    render json: { user: current_user.as_json, message: 'Bem-vindo ao painel' }, status: :ok
  end
end