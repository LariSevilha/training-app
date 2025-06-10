module Api
  module V1
    class DashboardController < ApplicationController
      before_action :ensure_master, only: [:index]
      respond_to :json

      def index
        render json: current_user.as_json(
          only: [:id, :name, :email, :role],
          include: {
            trainings: { only: [:id, :serie_amount, :repeat_amount, :exercise_name, :video, :weekday] },
            meals: { only: [:id, :meal_type, :weekday], include: { comidas: { only: [:id, :name, :amount] } } },
            weekly_pdfs: { only: [:id, :weekday, :pdf_url, :notes], methods: [:pdf_filename] }
          }
        ), status: :ok
      end
    end
  end
end