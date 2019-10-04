# frozen_string_literal: true

module API
  module Support
    module Authentication
      def api_token
        RequestStore[:api_token] = headers['Authorization']
        unauthorized! 'Token not present in request' unless RequestStore[:api_token]

        RequestStore[:token] = AuthenticationService.verify(RequestStore[:api_token])
        unauthorized! 'Token expired or invalid' unless RequestStore[:token]

        RequestStore[:user_id] = RequestStore[:token].sub
      end
    end
  end
end
