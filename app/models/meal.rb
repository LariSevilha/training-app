class Meal < ApplicationRecord
  belongs_to :user
  has_many :comidas, dependent: :destroy
  validates :meal_type, presence: true
  accepts_nested_attributes_for :comidas, allow_destroy: true
end