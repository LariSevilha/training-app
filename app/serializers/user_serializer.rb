class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone_number, :cpf, :cref, :photo_url, :created_at, :updated_at 
  has_many :trainings, if: -> { object.is_a?(User) }
  has_many :meals, if: -> { object.is_a?(User) }
  has_many :weekly_pdfs, if: -> { object.is_a?(User) }

  def phone_number
    object.respond_to?(:phone_number) ? object.phone_number : nil
  end

  def cpf
    object.respond_to?(:cpf) ? object.cpf : nil
  end

  def cref
    object.respond_to?(:cref) ? object.cref : nil
  end

  def photo_url
    object.respond_to?(:photo_url) ? object.photo_url : nil
  end

  def registration_date
    return nil unless object.is_a?(User)
    object.registration_date&.strftime("%d/%m/%Y")
  end

  def expiration_date
    return nil unless object.is_a?(User)
    object.formatted_expiration_date
  end

  def plan_type
    return nil unless object.is_a?(User)
    object.plan_type
  end

  def plan_duration
    return nil unless object.is_a?(User)
    object.plan_duration
  end

  def error
    nil
  end
end