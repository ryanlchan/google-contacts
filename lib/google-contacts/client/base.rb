require "net/http"
require "nokogiri"
require "nori"
require "cgi"

module GContacts
  module Client
    class Base
      AUTH_URL = "https://accounts.google.com"
      DATA_URL = "https://www.google.com"

      attr_reader :feed_uri, :post_uri, :batch_uri

      def initialize(args)
        @options = args
      end

      def all(args={})
        response = http_request(:get, args.delete(:uri) || @uris[:all], args)
        List.new(Nori.parse(response))
      end

      private
      def build_query_string(params)
        return nil unless params

        query_string = ""

        params.each do |k, v|
          next unless v
          query_string << "&" unless query_string == ""
          query_string << "#{k}=#{CGI::escape(v.to_s)}"
        end

        query_string == "" ? nil : query_string
      end

      def http_request(method, uri, args)
        headers = args[:headers] || {}
        headers["Authorization"] = "Bearer #{@options[:access_token]}"
        headers["GData-Version"] = "3.0"

        http = Net::HTTP.new(uri.host, uri.port)
        http.set_debug_output(@options[:debug_output]) if @options[:debug_output]

        if @options[:verify_ssl]
          store = OpenSSL::X509::Store.new
          store.set_default_paths
          http.cert_store = store
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        http.start

        query_string = build_query_string(args[:params])

        # GET
        if method == :get
          if query_string
            response = http.request_get("#{uri.request_uri}?#{query_string}", headers)
          else
            response = http.request_get(uri.request_uri, headers)
          end
        # POST
        elsif method == :post
          response = http.request_post(uri.request_uri, query_string, headers)
        # PUT
        elsif method == :put
          response = http.request_put(uri.request_uri, query_string, headers)
        end

        unless response.code == "200"
          raise Net::HTTPError.new("#{response.message} (#{response.code})", response)
        end

        response.body
      end
    end
  end
end
