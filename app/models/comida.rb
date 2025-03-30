class Comida < ApplicationRecord
  belongs_to :meal
  belongs_to :amount_meal, optional: true

  validates :meal_id, presence: true
  validates :name, presence: true
end
