module GContacts
  class Element
    attr_reader :edit_uri, :id, :title, :updated, :content, :data

    ##
    # Creates a new element by parsing the returned entry from Google
    # @param [Hash] entry Hash representation of the XML returned from Google
    #
    def initialize(entry)
      @id, @updated, @content, @title = entry["id"], entry["updated"], entry["contact"], entry["title"]
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
      entry["link"].each do |link|
        if link["@rel"] == "edit"
          @edit_uri = URI(link["@href"]).request_uri
          break
        end
      end
    end

    ##
    # Immediately removes the element on Google
    def delete!

    end

    ##
    # Flags the element for deletion
    def delete
    end

    ##
    # Immediately updates the element on Google
    def update!
    end

    ##
    # Flags the element to be updated
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