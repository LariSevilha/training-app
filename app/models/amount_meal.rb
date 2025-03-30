class AmountMeal < ApplicationRecord
  has_many :comidas, dependent: :destroy

  validates :amount, presence: true
end
