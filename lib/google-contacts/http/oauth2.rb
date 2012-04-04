# OAuth2 adapter
module GContacts
  module HTTP
    class OAuth2
      attr_accessor :headers

      def initialize(klass, args={})
        # Everything is setup for us already
        if klass.is_a?(::OAuth2::AccessToken)
          @token = klass

        # Working with an existing client and a token, have to construct the token class
        elsif klass.is_a?(::OAuth2::Client)
          unless args[:refresh_token] or args[:access_token]
            raise MissingToken, "Must pass either :refresh_token or :access_token"
          end

          @token = ::OAuth2::AccessToken.from_hash(klass, :refresh_token => args[:refresh_token], :access_token => args[:access_token])
        else
          raise ArgumentError, "Invalid arguments passed"
        end

        @token.client.site = Client::Base::DATA_URL
        @token.client.options[:raise_errors] = false
        @headers = {}
      end

      # Update the token
      def refresh!
        unless @token.refresh_token
          raise MissingToken, "Cannot refresh the access token without a refresh token"
        end

        @token.client.site = Client::Base::AUTH_URL
        @token = @token.refresh
        @token.client.site = Client::Base::DATA_URL
      end

      def get(uri, params={})
        response = token.get(uri, :params => params, :headers => @headers)
        unless response.code == "200"
          raise HTTPError.new("Non-OK HTTP response (#{response.status})", response.status)
        end

        response.body
      end
    end
  end
end