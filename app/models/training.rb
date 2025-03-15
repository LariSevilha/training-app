class Training < ApplicationRecord
  belongs_to :user
  belongs_to :serie
  belongs_to :repeat
  belongs_to :exercise
end
