class User < ApplicationRecord
  has_secure_password
  
  belongs_to :master_user, optional: true
  has_many :trainings, dependent: :destroy
  has_many :meals, dependent: :destroy
  has_many :weekly_pdfs, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_one_attached :avatar

  # Nested attributes
  accepts_nested_attributes_for :trainings, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :meals, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :weekly_pdfs, allow_destroy: true, reject_if: :all_blank

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true
  validates :name, presence: true

  enum plan_type: { manual: 'manual', pdf: 'pdf' }

  # Método para processar nested attributes de trainings com series e repeats
  def trainings_attributes=(attributes)
    attributes.each do |index, training_attrs|
      training = if training_attrs[:id].present?
                   trainings.find(training_attrs[:id])
                 else
                   trainings.build
                 end

      if training_attrs[:_destroy] == '1' || training_attrs[:_destroy] == true
        training.mark_for_destruction
      else
        training.assign_attributes(training_attrs.except(:series_attributes, :repeats_attributes))
        
        # Handle series_attributes
        if training_attrs[:series_attributes].present?
          training_attrs[:series_attributes].each do |series_index, series_attrs|
            if series_attrs[:_destroy] == '1' || series_attrs[:_destroy] == true
              if series_attrs[:id].present?
                series = Series.find(series_attrs[:id])
                training.training_series.where(serie: series).first&.mark_for_destruction
              end
            else
              if series_attrs[:id].present?
                series = Series.find(series_attrs[:id])
                series.update(amount: series_attrs[:amount])
              else
                series = Series.create!(amount: series_attrs[:amount])
                training.training_series.build(serie: series)
              end
            end
          end
        end

        # Handle repeats_attributes
        if training_attrs[:repeats_attributes].present?
          training_attrs[:repeats_attributes].each do |repeat_index, repeat_attrs|
            if repeat_attrs[:_destroy] == '1' || repeat_attrs[:_destroy] == true
              if repeat_attrs[:id].present?
                repeat = Repeat.find(repeat_attrs[:id])
                training.training_repeats.where(repeat: repeat).first&.mark_for_destruction
              end
            else
              if repeat_attrs[:id].present?
                repeat = Repeat.find(repeat_attrs[:id])
                repeat.update(amount: repeat_attrs[:amount])
              else
                repeat = Repeat.create!(amount: repeat_attrs[:amount])
                training.training_repeats.build(repeat: repeat)
              end
            end
          end
        end
      end
    end
  end

  def avatar_url
    avatar.attached? ? Rails.application.routes.url_helpers.url_for(avatar) : nil
  end
end