# encoding: US-ASCII

require "net/https"
require "nokogiri"
require "nori"
require "cgi"
require "json"

module GContacts
  class Client
    attr_reader :options

    API_URI = {
      :oauth => {:update => "https://accounts.google.com/o/oauth2/token"},
      :contacts => {:all => "https://www.google.com/m8/feeds/contacts/default/%s",
                    :get => "https://www.google.com/m8/feeds/contacts/default/%s/%s",
                    :update => "https://www.google.com/m8/feeds/contacts/default/full/%s",
                    :create => URI("https://www.google.com/m8/feeds/contacts/default/full"),
                    :batch => URI("https://www.google.com/m8/feeds/contacts/default/full/batch")},
      :groups => {:all => "https://www.google.com/m8/feeds/groups/default/%s", :create => URI("https://www.google.com/m8/feeds/groups/default/full"), :get => "https://www.google.com/m8/feeds/groups/default/%s/%s", :update => "https://www.google.com/m8/feeds/groups/default/full/%s", :batch => URI("https://www.google.com/m8/feeds/groups/default/full/batch")}
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
    # Checks whether the current token is valid. This is done by trying to retrieve one contact.
    #
    # @return [Boolean] True if the current access_token is valid, false otherwise.
    def valid_token?
      begin
        self.all :params => {:limit => 1}
      rescue Exception => e
        return false
      end
      true
    end

    ##
    # Refreshes the authentication token.
    # @param [String] client_id of the application
    # @param [String] client_secret of the application
    # @param [String] refresh_token which was originally passed to the user on login
    #
    # @raise [Net::HTTPError]
    # @return [Hash] the refreshed access token hash
    def refresh_token!(client_id, client_secret, refresh_token)
      uri = API_URI[:oauth]
      raise ArgumentError, "Unsupported type given" unless uri

      data = http_request(:post, URI(uri[:update]), :body => {:client_id => client_id, :client_secret => client_secret, :refresh_token => refresh_token, :grant_type => "refresh_token"}.collect{|k,v| "#{k}=#{v}"}.join("&"))

      token = JSON.parse(data)

      @options[:access_token] = token["access_token"]
      @options[:expires_at] = DateTime.now + Rational(token["expires_in"].to_i, 86400)
      token
    end

    ##
    # Retrieves all contacts/groups up to the default limit
    # @param [Hash] args
    # @option args [Hash, Optional] :params Query string arguments when sending the API request
    # @option args [Hash, Optional] :headers Any additional headers to pass with the API request
    # @option args [Symbol, Optional] :api_type Override which part of the API is called, can either be :contacts or :groups
    #
    # @raise [Net::HTTPError]
    #
    # @return [GContacts::List] List containing all the returned entries
    def all(args={})
      uri = API_URI[args.delete(:api_type) || @options[:default_type]]
      raise ArgumentError, "Unsupported type given" unless uri

      response = http_request(:get, URI(uri[:all] % (args.delete(:type) || :full)), args)
      List.new(nori_parse(response))
    end

    ##
    # Repeatedly calls {#find_in_batches} until all data is loaded
    # @param [Hash] args
    # @option args [Hash, Optional] :params Query string arguments when sending the API request
    # @option args [Hash, Optional] :headers Any additional headers to pass with the API request
    # @option args [Symbol, Optional] :api_type Override which part of the API is called, can either be :contacts or :groups
    # @option args [Symbol, Optional] :type What data type to request, can either be :full or :base, defaults to :base
    #
    # @raise [Net::HTTPError]
    #
    # @return [GContacts::List] List containing all the returned entries
    def find_in_batches(args={}, &block)
      uri = API_URI[args.delete(:api_type) || @options[:default_type]]
      raise ArgumentError, "Unsupported type given" unless uri
      uri = URI(uri[:all] % (args.delete(:type) || :full))

      contacts = List.new()

      until (uri.nil?) do
        batch_contacts = List.new(nori_parse(http_request(:get, uri, args)))
        block.call(batch_contacts) if block_given?
        contacts.merge!(batch_contacts) unless block_given?
        uri = (uri == batch_contacts.next_uri ? nil : batch_contacts.next_uri)
        # If we have any params remove them, the URI Google returns will include them
        args.delete(:params) if uri
      end
      contacts
    end
    alias :paginate_all :find_in_batches

    ##
    # Get a single contact or group from the server
    # @param [String] id ID to update
    # @param [Hash] args
    # @option args [Hash, Optional] :params Query string arguments when sending the API request
    # @option args [Hash, Optional] :headers Any additional headers to pass with the API request
    # @option args [Symbol, Optional] :api_type Override which part of the API is called, can either be :contacts or :groups
    # @option args [Symbol, Optional] :type What data type to request, can either be :full or :base, defaults to :base
    #
    # @raise [Net::HTTPError]
    # @raise [GContacts::InvalidRequest]
    #
    # @return [GContacts::Element] Single entry found on
    def get(id, args={})
      uri = API_URI[args.delete(:api_type) || @options[:default_type]]
      raise ArgumentError, "Unsupported type given" unless uri

      response = nori_parse(http_request(:get, URI(uri[:get] % [args.delete(:type) || :full, id]), args))

      if response and response["entry"]
        Element.new(response["entry"])
      else
        nil
      end
    end

    ##
    # Immediately creates the element on Google
    #
    # @raise [Net::HTTPError]
    # @raise [GContacts::InvalidRequest]
    # @raise [GContacts::InvalidResponse]
    # @raise [GContacts::InvalidKind]
    #
    # @return [GContacts::Element] Updated element returned from Google
    def create!(element)
      uri = API_URI["#{element.category}s".to_sym]
      raise InvalidKind, "Unsupported kind #{element.category}" unless uri

      xml = "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}"

      data = nori_parse(http_request(:post, uri[:create], :body => xml, :headers => {"Content-Type" => "application/atom+xml"}))
      unless data["entry"]
        raise InvalidResponse, "Created but response wasn't a valid element"
      end

      Element.new(data["entry"])
    end

    ##
    # Immediately updates the element on Google
    # @param [GContacts::Element] Element to update
    #
    # @raise [Net::HTTPError]
    # @raise [GContacts::InvalidResponse]
    # @raise [GContacts::InvalidRequest]
    # @raise [GContacts::InvalidKind]
    #
    # @return [GContacts::Element] Updated element returned from Google
    def update!(element)
      uri = API_URI["#{element.category}s".to_sym]
      raise InvalidKind, "Unsupported kind #{element.category}" unless uri

      xml = "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}"

      data = nori_parse(http_request(:put, URI(uri[:get] % [:base, File.basename(element.id)]), :body => xml, :headers => {"Content-Type" => "application/atom+xml", "If-Match" => element.etag}))
      unless data["entry"]
        raise InvalidResponse, "Updated but response wasn't a valid element"
      end

      Element.new(data["entry"])
    end

    ##
    # Immediately removes the element on Google
    # @param [GContacts::Element] Element to delete
    #
    # @raise [Net::HTTPError]oup
    # @raise [GContacts::InvalidRequest]
    #
    def delete!(element)
      uri = API_URI["#{element.category}s".to_sym]
      raise InvalidKind, "Unsupported kind #{element.category}" unless uri

      http_request(:delete, URI(uri[:get] % [:base, File.basename(element.id)]), :headers => {"Content-Type" => "application/atom+xml", "If-Match" => element.etag})

      true
    end

    ##
    # Sends an array of {GContacts::Element} to be updated/created/deleted
    # @param [Array] list Array of elements
    # @param [GContacts::List] list Array of elements
    # @param [Hash] args
    # @option args [Hash, Optional] :params Query string arguments when sending the API request
    # @option args [Hash, Optional] :headers Any additional headers to pass with the API request
    # @option args [Symbol, Optional] :api_type Override which part of the API is called, can either be :contacts or :groups
    #
    # @raise [Net::HTTPError]
    # @raise [GContacts::InvalidResponse]
    # @raise [GContacts::InvalidRequest]
    # @raise [GContacts::InvalidKind]
    #
    # @return [GContacts::List] List of elements with the results from the server
    def batch!(list, args={})
      return List.new if list.empty?

      uri = API_URI[args.delete(:api_type) || @options[:default_type]]
      raise ArgumentError, "Unsupported type given" unless uri

      xml = "<?xml version='1.0' encoding='UTF-8'?>\n"
      xml << "<feed xmlns='http://www.w3.org/2005/Atom' xmlns:gContact='http://schemas.google.com/contact/2008' xmlns:gd='http://schemas.google.com/g/2005' xmlns:batch='http://schemas.google.com/gdata/batch'>\n"
      list.each do |element|
        xml << element.to_xml(true) if element.has_modifier?
      end
      xml << "</feed>"

      results = http_request(:post, uri[:batch], :body => xml, :headers => {"Content-Type" => "application/atom+xml"})
      List.new(nori_parse(results))
    end

    def set_image(element, filename)
      result = http_request(:put, URI.parse("https://www.google.com/m8/feeds/photos/media/default/#{element.id}"), :body => File.read(filename), :headers => {"Content-Type" => "image/#{image_type(filename)}", "If-Match" => "*", "Slug" => File.basename(filename), "Content-Length" => File.read(filename).size.to_s, "Expect" => "100-continue"})
    end

    private
    def image_type(file)
      case IO.read(file, 10)
        when /^GIF8/ then 'gif'
        when /^\x89PNG/ then 'png'
        when /^\xff\xd8\xff\xe0\x00\x10JFIF/ then 'jpeg'
        when /^\xff\xd8\xff\xe1(.*){2}Exif/ then 'jpeg'
        when /^BM/ then 'bmp'
      else 'unknown'
      end
    end

    def build_query_string(params)
      return nil unless params

      query_string = ""

      params = translate_parameters(params)
      params.each do |k, v|
        next unless v
        query_string << "&" unless query_string == ""
        query_string << "#{k}=#{CGI::escape(v.to_s)}"
      end

      query_string == "" ? nil : query_string
    end

    def translate_parameters(params)
      params.inject({}) do |all, pair|
        key, value = pair
        unless value.nil?
          key = case key
                when :limit
                  'max-results'
                when :offset
                  value = value.to_i + 1
                  'start-index'
                when :order
                  all['sortorder'] = 'descending' if params[:descending].nil?
                  'orderby'
                when :descending
                  value = value ? 'descending' : 'ascending'
                  'sortorder'
                when :updated_after
                  value = value.iso8601 if value.respond_to? :iso8601
                  'updated-min'
                else key
                end

          all[key] = value
        end
        all
      end
    end

    def http_request(method, uri, args)
      query_string = build_query_string(args[:params])
      token = @options[:access_token]
      headers = args[:headers] || {}
      headers["GData-Version"] = "3.0"

      if token.is_a?(String)
        request_uri = query_string ? "#{uri.request_uri}?#{query_string}" : uri.request_uri
        headers["Authorization"] = "Bearer #{@options[:access_token]}"

        http = Net::HTTP.new(uri.host, uri.port)
        http.set_debug_output(@options[:debug_output]) if @options[:debug_output]
        http.use_ssl = true

        if @options[:verify_ssl]
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        http.start

        # GET
        if method == :get
          response = http.request_get(request_uri, headers)
        # POST
        elsif method == :post
          response = http.request_post(request_uri, args.delete(:body), headers)
        # PUT
        elsif method == :put
          response = http.request_put(request_uri, args.delete(:body), headers)
        # DELETE
        elsif method == :delete
          response = http.request(Net::HTTP::Delete.new(request_uri, headers))
        else
          raise ArgumentError, "Invalid method #{method}"
        end
      elsif token.is_a?(OAuth::AccessToken)
        request_uri = query_string ? "#{uri.to_s}?#{query_string}" : uri.to_s
        if method == :get
          response = token.get(request_uri, headers)
        # POST
        elsif method == :post
          response = token.post(request_uri, args.delete(:body), headers)
        # PUT
        elsif method == :put
          response = token.put(request_uri, args.delete(:body), headers)
        # DELETE
        elsif method == :delete
          response = token.delete(request_uri, headers)
        else
          raise ArgumentError, "Invalid method #{method}"
        end
      end
      if response.code == "400" or response.code == "412" or response.code == "404"
        raise InvalidRequest.new("#{response.body} (HTTP #{response.code})")
      elsif response.code == "401"
        raise Unauthorized.new(response.message)
      elsif response.code != "200" and response.code != "201"
        raise Net::HTTPError.new("#{response.message} (#{response.code})", response)
      end

      response.body
    end

    # Wrapper to send arguments to Nori's new instance-based parser
    def nori_parse(args)
      @nori_parser ||= Nori.new
      @nori_parser.parse(args)
    end

  end
end
