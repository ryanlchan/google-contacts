# OAuth2 adapter
module GContacts
  module HTTP
    class OAuth2
      attr_accessor :headers

      def initialize(args)
        # Everything is setup for us already
        if args[:token]
          @token = args[:token]

        # Working with an existing client and a token, have to construct the token class
        elsif args[:client]
          unless args[:refresh_token] or args[:access_token]
            raise MissingToken, "Must pass either :refresh_token or :access_token"
          end

          @token = ::OAuth2::AccessToken.from_hash(args.delete(:client), :refresh_token => args[:refresh_token], :access_token => args[:access_token])
        else
          raise ArgumentError, "Invalid arguments passed"
        end

        @token.client.site = GContacts::Client::DATA_URL
        @token.client.options[:raise_errors] = false
        @headers = {}
      end

      # Update the token
      def refresh!
        unless @token.refresh_token
          raise Missingtoken, "Cannot refresh the access token without a refresh token"
        end

        @token.client.site = GContacts::Client::AUTH_URL
        @token = @token.refresh
        @token.client.site = GContacts::Client::DATA_URL
      end


      def get(uri, params={})
        response = token.get(uri, :params => params, :headers => @headers)
      end
    end
  end
end