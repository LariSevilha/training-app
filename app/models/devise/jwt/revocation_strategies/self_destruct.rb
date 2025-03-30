module Devise
  module JWT
    module RevocationStrategies
      class SelfDestruct
        def self.jwt_revoked?(_payload, _user)
          false # Sempre permite o uso do token
        end

        def self.revoke_jwt(_payload, user)
          user.destroy! # Exclui o usuário ao revogar o token
        end
      end
    end
  end
end