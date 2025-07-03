class Training < ApplicationRecord
  belongs_to :user
  has_many_attached :photos
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :video, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "deve ser uma URL válida" }, allow_blank: true

  enum weekday: {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  def photo_urls
    photos.attached? ? photos.map { |photo| Rails.application.routes.url_helpers.url_for(photo) } : []
  end
end