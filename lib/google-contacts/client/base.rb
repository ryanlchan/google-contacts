module GContacts
  module Client
    class Base
      AUTH_URL = "https://accounts.google.com"
      DATA_URL = "https://www.google.com"

      attr_reader :feed_uri, :post_uri, :batch_uri

      def initialize(args)
        auth = args.delete(:auth)

        if auth.is_a?(Signet::OAuth2::Client)
          @http = GContacts::HTTP::Signet.new(*auth)
        else
          @http = GContacts::HTTP::OAuth2.new(*auth)
        end

        @http.headers["GData-Version"] = "3.0"
      end
    end
  end
end