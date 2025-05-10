class Training < ApplicationRecord
  belongs_to :user
  enum :weekday, {
    sunday: 0, monday: 1, tuesday: 2, wednesday: 3,
    thursday: 4, friday: 5, saturday: 6
  }
  

  validates :serie_amount, :repeat_amount, :exercise_name, :weekday, presence: true

end