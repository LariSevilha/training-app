class Repeat < ApplicationRecord
  has_many :trainings, dependent: :destroy

  validates :amount, presence: true
end
