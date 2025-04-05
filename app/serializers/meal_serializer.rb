class MealSerializer < ActiveModel::Serializer
  attributes :id, :meal_type
  has_many :comidas

  def comidas
    object.comidas || []
  end
end