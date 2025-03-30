class Meal < ApplicationRecord
  belongs_to :user
  has_many :comidas, dependent: :destroy

  validates :user_id, presence: true
end
