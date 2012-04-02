# Signet adapter (Coming later)
module GContacts
  module HTTP
    class Signet
      attr_accessor :headers

      def initialize(args)
        @headers = {}
      end

      # Update the token
      def refresh!
      end

      def get(uri, params={})
      end
    end
  end
end