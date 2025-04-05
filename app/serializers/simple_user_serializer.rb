class SimpleUserSerializer < ActiveModel::Serializer
    attributes :id, :name, :role
  end