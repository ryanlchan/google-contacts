require "net/https"
require "nokogiri"
require "nori"
require "cgi"

module GContacts
  class Client
    API_URI = {
      :contacts => {:all => URI("https://www.google.com/m8/feeds/contacts/default/full"), :create => URI("https://www.google.com/m8/feeds/contacts/default/full"), :get => "https://www.google.com/m8/feeds/contacts/default/base/%s", :update => "https://www.google.com/m8/feeds/contacts/default/full/%s", :batch => URI("https://www.google.com/m8/feeds/contacts/default/batch")},
      :groups => {:all => URI("https://www.google.com/m8/feeds/groups/default/full"), :create => URI("https://www.google.com/m8/feeds/groups/default/full"), :get => "https://www.google.com/m8/feeds/groups/default/base/%s", :update => "https://www.google.com/m8/feeds/groups/default/full/%s", :batch => URI("https://www.google.com/m8/feeds/groups/default/batch")}
    }

    ##
    # Initializes a new client
    # @param [Hash] args
    # @option args [String] :access_token OAuth2 access token
    # @option args [Symbol] :default_type Which API to call by default, can either be :contacts or :groups, defaults to :contacts
    # @option args [IO, Optional] :debug_output Dump the results of HTTP requests to the given IO
    #
    # @raise [GContacts::MissingToken]
    #
    # @return [GContacts::Client]
    def initialize(args)
      unless args[:access_token]
        raise ArgumentError, "Access token must be passed"
      end

      @options = {:default_type => :contacts}.merge(args)
    end

    ##
    # Retrieves all contacts/groups up to the default limit
    # @param [Hash] args
    # @option args [Hash, Optional] :params Query string arguments when sending the API request
    # @option args [Hash, Optional] :headers Any additional headers to pass with the API request
    # @option args [Symbol, Optional] :type Override which part of the API is called, can either be :contacts or :groups
    #
    # @raise [Net::HTTPError]
    #
    # @return [GContacts::List] List containing all the returned entries
    def all(args={})
      response = http_request(:get, API_URI[args.delete(:type) || @options[:default_type]][:all], args)
      List.new(Nori.parse(response))
    end

    ##
    # Repeatedly calls {#all} until all data is loaded
    # @param [Hash] args
    # @option args [Hash, Optional] :params Query string arguments when sending the API request
    # @option args [Hash, Optional] :headers Any additional headers to pass with the API request
    # @option args [Symbol, Optional] :type Override which part of the API is called, can either be :contacts or :groups
    #
    # @raise [Net::HTTPError]
    #
    # @return [GContacts::List] List containing all the returned entries
    def paginate_all(args={})
      uri = API_URI[args.delete(:type) || @options[:default_type]][:all]

      while true do
        list = List.new(Nori.parse(http_request(:get, uri, args)))
        list.each {|entry| yield entry}

        # Nothing left to paginate
        # Or just to be safe, we're about to get caught in an infinite loop
        if list.empty? or list.next_uri.nil? or uri == list.next_uri
          break
        end

        uri = list.next_uri
      end
    end

    ##
    # Get a single contact or group from the server
    # @param [String] id ID to update
    # @param [Hash] args
    # @option args [Hash, Optional] :params Query string arguments when sending the API request
    # @option args [Hash, Optional] :headers Any additional headers to pass with the API request
    # @option args [Symbol, Optional] :type Override which part of the API is called, can either be :contacts or :groups
    #
    # @raise [Net::HTTPError]
    #
    # @return [GContacts::Entry] Single entry found on
    def get(id, args={})
      uri = URI(API_URI[args.delete(:type) || @options[:default_type]][:get] % id)
      response = Nori.parse(http_request(:get, uri, args))

      if response and response["entry"]
        Element.new(response["entry"])
      else
        nil
      end
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
      http.use_ssl = true

      if @options[:verify_ssl]
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      else
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.start

      query_string = build_query_string(args[:params])
      request_uri = query_string ? "#{uri.request_uri}?#{query_string}" : uri.request_uri

      # GET
      if method == :get
        response = http.request_get(request_uri, headers)
      # POST
      elsif method == :post
        response = http.request_post(request_uri, args.delete(:body), headers)
      # PUT
      elsif method == :put
        response = http.request_put(request_uri, args.delete(:body), headers)
      else
        raise ArgumentError, "Invalid method #{method}"
      end

      if response.code == "400" or response.code == "412" or response.code == "404"
        raise InvalidRequest.new("#{response.body} (HTTP #{response.code})")
      elsif response.code != "200" and response.code != "201"
        raise Net::HTTPError.new("#{response.message} (#{response.code})", response)
      end

      response.body
    end
  end
end
