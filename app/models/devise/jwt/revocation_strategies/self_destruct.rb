module Devise
  module JWT
    module RevocationStrategies
      class SelfDestruct
        def self.jwt_revoked?(payload, user)
          false # Tokens are never revoked
        end

        def self.revoke_jwt(payload, user)
          user.destroy! # Destroy the user record when the token is revoked
        end
      end
    end
  end
end