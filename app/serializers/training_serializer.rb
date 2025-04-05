class TrainingSerializer < ActiveModel::Serializer
    attributes :id, :serie_amount, :repeat_amount, :exercise_name, :video
  end