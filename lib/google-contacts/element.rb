module GContacts
  class Element
    attr_reader :edit_uri, :id, :title, :updated, :content, :data, :etag

    ##
    # Creates a new element by parsing the returned entry from Google
    # @param [Hash] entry Hash representation of the XML returned from Google
    #
    def initialize(entry)
      @id, @updated, @content, @title = entry["id"], entry["updated"], entry["contact"], entry["title"]
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
    # Flags the element for creation, must be passed through {GContacts::Client#batch} for the change to take affect.
    def create
    end

    ##
    # Flags the element for deletion, must be passed through {GContacts::Client#batch} for the change to take affect.
    def delete
    end

    ##
    # Flags the element to be updated, must be passed through {GContacts::Client#batch} for the change to take affect.
    def update

    end

    def inspect
      "#<#{self.class.name} title: \"#{@title}\", updated: \"#{@updated}\">"
    end

    private
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