module GContacts
  class Element
    attr_accessor :title, :content, :data, :category, :etag, :group_id
    attr_reader :id, :edit_uri, :modifier_flag, :updated, :batch

    ##
    # Creates a new element by parsing the returned entry from Google
    # @param [Hash, Optional] entry Hash representation of the XML returned from Google
    #
    def initialize(entry=nil)
      @data = {}
      return unless entry

      @id, @updated, @content, @title, @etag = entry["id"], entry["updated"], entry["content"], entry["title"], entry["@gd:etag"]
      if entry["category"]
        @category = entry["category"]["@term"].split("#", 2).last
        @category_tag = entry["category"]["@label"] if entry["category"]["@label"]
      end

      # Parse out all the relevant data
      entry.each do |key, unparsed|
        if key =~ /^gd:/
          if unparsed.is_a?(Array)
            @data[key] = unparsed.map {|v| parse_element(v)}
          else
            @data[key] = [parse_element(unparsed)]
          end
        elsif key =~ /^batch:(.+)/
          @batch ||= {}

          if $1 == "interrupted"
            @batch["status"] = "interrupted"
            @batch["code"] = "400"
            @batch["reason"] = unparsed["@reason"]
            @batch["status"] = {"parsed" => unparsed["@parsed"].to_i, "success" => unparsed["@success"].to_i, "error" => unparsed["@error"].to_i, "unprocessed" => unparsed["@unprocessed"].to_i}
          elsif $1 == "id"
            @batch["status"] = unparsed
          elsif $1 == "status"
            if unparsed.is_a?(Hash)
              @batch["code"] = unparsed["@code"]
              @batch["reason"] = unparsed["@reason"]
            else
              @batch["code"] = unparsed.attributes["code"]
              @batch["reason"] = unparsed.attributes["reason"]
            end

          elsif $1 == "operation"
            @batch["operation"] = unparsed["@type"]
          end
        end
      end

      if entry["gContact:groupMembershipInfo"]
        @modifier_flag = :delete if entry["gContact:groupMembershipInfo"]["@deleted"] == "true"
        @group_id = entry["gContact:groupMembershipInfo"]["@href"]
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
      xml = "<atom:entry xmlns:atom='http://www.w3.org/2005/Atom' xmlns:gd='http://schemas.google.com/g/2005'"
      xml << " gd:etag='#{@etag}'" if @etag
      xml << ">\n"

      if batch
        xml << "  <batch:id>#{@modifier_flag}</batch:id>\n"
        xml << "  <batch:operation type='#{@modifier_flag == :create ? "insert" : @modifier_flag}'/>\n"
      end

      # While /base/ is whats returned, /full/ is what it seems to actually want
      if @id
        xml << "  <id>#{@id.to_s.gsub("/base/", "/full/")}</id>\n"
      end

      unless @modifier_flag == :delete
        xml << "  <atom:category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2008##{@category}'/>\n"
        xml << "  <updated>#{Time.now.utc.iso8601}</updated>\n"
        xml << "  <atom:content type='text'>#{@content}</atom:content>\n"
        xml << "  <atom:title>#{@title}</atom:title>\n"
        xml << "  <gContact:groupMembershipInfo deleted='false' href='#{@group_id}'/>\n" if @group_id

        @data.each do |key, parsed|
          xml << handle_data(key, parsed, 2)
        end
      end

      xml << "</atom:entry>\n"
    end

    ##
    # Flags the element for creation, must be passed through {GContacts::Client#batch} for the change to take affect.
    def create;
      unless @id
        @modifier_flag = :create
      end
    end

    ##
    # Flags the element for deletion, must be passed through {GContacts::Client#batch} for the change to take affect.
    def delete;
      if @id
        @modifier_flag = :delete
      else
        @modifier_flag = nil
      end
    end

    ##
    # Flags the element to be updated, must be passed through {GContacts::Client#batch} for the change to take affect.
    def update;
      if @id
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

      # Need to check for any additional attributes to attach since they can be mixed in
      misc_keys = 0
      if data.is_a?(Hash)
        misc_keys = data.length

        data.each do |key, value|
          next unless key =~ /^@(.+)/
          xml << " #{$1}='#{value}'"
          misc_keys -= 1
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
      if !data.is_a?(Array) and !data.is_a?(Hash)
        xml << ">"
        xml << data.to_s
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