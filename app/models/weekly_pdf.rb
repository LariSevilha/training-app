class WeeklyPdf < ApplicationRecord
  belongs_to :user
  has_one_attached :pdf  
  def pdf_url
    pdf.attached? ? Rails.application.routes.url_helpers.rails_blob_url(pdf, only_path: true) : nil
  end
end