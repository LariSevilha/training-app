class SuperUserSerializer < ActiveModel::Serializer
    attributes :id, :name, :email, :phone_number, :created_at, :updated_at, :photo_url, :role

    def role
        'super'
    end

    def photo_url
        object.photo_url
    end
end