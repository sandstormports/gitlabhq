module Devise
  module Strategies
    class Sandstorm < Authenticatable
      def authenticate!
        Rails.logger.info 'Authenticating Sandstorm'
        userid = request.headers['HTTP_X_SANDSTORM_USER_ID']
        username = request.headers['HTTP_X_SANDSTORM_USERNAME']
        u = User.where(username: userid).first
        if !u
          opts = {}
          opts[:name] = username
          opts[:password] = "xyzzy123!xyzzy"
          opts[:username] = userid
          opts[:email] = userid + "@example.com"
          u = User.create(opts)
          if u.save
            Rails.logger.info 'User was successfully created.'
          else
            Rails.logger.error 'User could not be created'
            Rails.logger.error u.errors
          end

        end
        Rails.logger.info 'Done Authenticating Sandstorm'
        success!(u)
      end
      def valid?
        !!request.headers['HTTP_X_SANDSTORM_USER_ID']
      end
    end
  end
end
