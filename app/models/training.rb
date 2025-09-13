class Training < ApplicationRecord
  belongs_to :user 
  
  has_many :training_exercises, dependent: :destroy
  has_many :exercises, through: :training_exercises
  
  has_many_attached :photos
  
  accepts_nested_attributes_for :training_exercises, 
                                allow_destroy: true, 
                                reject_if: :all_blank
  
  enum weekday: { 
    monday: 0, 
    tuesday: 1, 
    wednesday: 2, 
    thursday: 3, 
    friday: 4, 
    saturday: 5, 
    sunday: 6 
  }
  
  def photo_urls
    photos.attached? ? photos.map { |photo| Rails.application.routes.url_helpers.url_for(photo) } : []
  end
end