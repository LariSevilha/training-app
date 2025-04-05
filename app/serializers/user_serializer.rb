class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role
  has_many :trainings
  has_many :meals
end