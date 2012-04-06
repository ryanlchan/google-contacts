module GContacts
  class Element
    attr_accessor :title, :content, :data, :category
    attr_reader :id, :edit_uri, :modifier_flag, :updated, :etag

    ##
    # Creates a new element by parsing the returned entry from Google
    # @param [Hash, Optional] entry Hash representation of the XML returned from Google
    #
    def initialize(entry=nil)
      return unless entry
      @id, @updated, @content, @title = entry["id"], entry["updated"], entry["contact"], entry["title"]
      @category = entry["category"]["@term"].match(/contact$/i)
      @etag = entry["@gd:etag"].gsub('"', "") if entry["@gd:etag"]
      @data = {}

      # Parse out all the relevant data
      entry.each do |key, unparsed|
        next unless key =~ /^gd:/

        if unparsed.is_a?(Array)
          @data[key] = unparsed.map {|v| parse_element(v)}
        else
          @data[key] = [parse_element(unparsed)]
        end
      end

      # Need to know where to send the update request
      if entry["link"].is_a?(Array)
        entry["link"].each do |link|
          if link["@rel"] == "edit"
            @edit_uri = URI(link["@href"])
            break
          end
        end
      end
    end

    ##
    # Converts the entry into XML to be sent to Google
    def to_xml(batch=false)
      xml = batch ? "" : "<?xml version='1.0' encoding='UTF-8'?>\n"
      xml << "<entry"
      xml << " gd:etag='#{@etag}'" if @etag
      xml << ">\n"

      if batch
        xml << "  <batch:id>#{@modifier_flag}</batch:id>\n"
        xml << "  <batch:operation type='#{@modifier_flag}'/>\n"
      end

      xml << "  <id>#{@id}</id>\n" unless @modifier_flag == :create

      unless @modifier_flag == :delete
        xml << "  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008##{@category}'/>\n"
        xml << "  <updated>#{Time.now.utc.iso8601}</updated>\n"
        xml << "  <content type='text'>#{@content}</content>\n"
        xml << "  <title>#{@title}</title>\n"

        @data.each do |key, parsed|
          xml << handle_data(key, parsed, 2)
        end
      end

      xml << "</entry>\n"
    end

    ##
    # Flags the element for creation, must be passed through {GContacts::Client#batch} for the change to take affect.
    def create;
      unless @edit_uri
        @modifier_flag = :create
      end
    end

    ##
    # Flags the element for deletion, must be passed through {GContacts::Client#batch} for the change to take affect.
    def delete;
      if @edit_uri
        @modifier_flag = :delete
      else
        @modifier_flag = nil
      end
    end

    ##
    # Flags the element to be updated, must be passed through {GContacts::Client#batch} for the change to take affect.
    def update;
      if @edit_uri
        @modifier_flag = :update
      end
    end

    ##
    # Whether {#create}, {#delete} or {#update} have been called
    def has_modifier?; !!@modifier_flag end

    def inspect
      "#<#{self.class.name} title: \"#{@title}\", updated: \"#{@updated}\">"
    end

    alias to_s inspect

    private
    # Evil ahead
    def handle_data(tag, data, indent)
      if data.is_a?(Array)
        xml = ""
        data.each do |value|
          xml << write_tag(tag, value, indent)
        end
      else
        xml = write_tag(tag, data, indent)
      end

      xml
    end

    def write_tag(tag, data, indent)
      xml = " " * indent
      xml << "<" << tag

      # Need to check for any additional attributes to attach since they can be mixed ni
      misc_keys = data.length
      if data.is_a?(Hash)
        data.each do |key, value|
          next unless key =~ /^@(.+)/
          xml << " #{$1}='#{value}'"
          misc_keys-= 1
        end

        # We explicitly converted the Nori::StringWithAttributes to a hash
        if data["text"] and misc_keys == 1
          data = data["text"]
        end

      # Nothing to filter out so we can just toss them on
      elsif data.is_a?(Nori::StringWithAttributes)
        data.attributes.each {|k, v| xml << " #{k}='#{v}'"}
      end

      # Just a string, can add it and exit quickly
      if data.is_a?(String)
        xml << ">"
        xml << data
        xml << "</#{tag}>\n"
        return xml
      # No other data to show, was just attributes
      elsif misc_keys == 0
        xml << "/>\n"
        return xml
      end

      # Otherwise we have some recursion to do
      xml << ">\n"

      data.each do |key, value|
        next if key =~ /^@/
        xml << handle_data(key, value, indent + 2)
      end

      xml << " " * indent
      xml << "</#{tag}>\n"
    end

    def parse_element(unparsed)
      data = {}

      if unparsed.is_a?(Hash)
        data = unparsed
      elsif unparsed.is_a?(Nori::StringWithAttributes)
        data["text"] = unparsed.to_s
        unparsed.attributes.each {|k, v| data["@#{k}"] = v}
      end

      data
    end
  end
end