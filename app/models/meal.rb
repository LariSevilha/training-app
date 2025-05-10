class Meal < ApplicationRecord
  belongs_to :user
  has_many :comidas, dependent: :destroy

  accepts_nested_attributes_for :comidas, allow_destroy: true

  enum :weekday, {
  sunday: 0, monday: 1, tuesday: 2, wednesday: 3,
  thursday: 4, friday: 5, saturday: 6
}

  validates :meal_type, :weekday, presence: true
end
