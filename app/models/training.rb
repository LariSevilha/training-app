class Training < ApplicationRecord
  belongs_to :user
  has_many_attached :photos
  validates :description, length: { maximum: 1000 }, allow_blank: true  
  enum weekday: {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }


  def photos_urls
    photos.map { |photo| Rails.application.routes.url_helpers.rails_blob_url(photo, only_path: true) }
  end
end
