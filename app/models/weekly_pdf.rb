class WeeklyPdf < ApplicationRecord
  belongs_to :user
  has_one_attached :pdf

  # Validação personalizada para garantir que o PDF esteja anexado
  validate :pdf_must_be_attached

  def pdf_url
    pdf.attached? ? Rails.application.routes.url_helpers.rails_blob_url(pdf, only_path: false, host: 'http://192.168.0.111:3000') : nil
  end

  def pdf_filename
    pdf.attached? ? pdf.filename.to_s : nil
  end

  private

  def pdf_must_be_attached
    errors.add(:pdf, 'deve ser anexado') unless pdf.attached?
  end
end