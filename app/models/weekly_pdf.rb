# app/models/weekly_pdf.rb
class WeeklyPdf < ApplicationRecord
  belongs_to :user
  has_one_attached :pdf

  # Removemos qualquer validação de presença para weekday
  def pdf_url
    pdf.attached? ? Rails.application.routes.url_helpers.rails_blob_url(pdf, only_path: true) : nil
  end

  def pdf_filename
    pdf.attached? ? pdf.filename.to_s : nil
  end
end