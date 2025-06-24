class UserSerializer < ActiveModel::Serializer
    attributes :id, :name, :email, :role, :registration_date, :expiration_date, :plan_type, :plan_duration, :error
    has_many :trainings
    has_many :meals
    has_many :weekly_pdfs
  
    def registration_date
      object.registration_date&.strftime("%d/%m/%Y")
    end
  
    def expiration_date
      object.expiration_date&.strftime("%d/%m/%Y")
    end
  end