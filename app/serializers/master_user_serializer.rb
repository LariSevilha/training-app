class MasterUserSerializer < ActiveModel::Serializer
    attributes :id, :name, :email, :phone_number, :cpf, :cref, :created_at, :updated_at, :photo_url, :role, :active
  
    def role
      'master'
    end
  
    def photo_url
      object.photo_url
    end
  
    def active
      # Considerar ativo se tem pelo menos uma API key ativa
      object.api_keys.where(active: true).exists?
    end
  end