require "nokogiri"
require "nori"

module GContacts
  module Client
    class Base
      AUTH_URL = "https://accounts.google.com"
      DATA_URL = "https://www.google.com"

      attr_reader :feed_uri, :post_uri, :batch_uri

      def initialize(http, *args)
        @http = http
        @http.headers["GData-Version"] = "3.0"
      end

      def all(args={})
        results = Nori.parse(@http.get(args[:uri] || @uris[:all], args.delete(:params)))

        List.new(results)
      end
    end
  end
end