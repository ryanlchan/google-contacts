module GContacts
  class List
    include Enumerable

    attr_reader :id, :updated, :title, :author, :per_page, :start_index, :total_results, :next_uri, :previous_uri, :category

    ##
    # Creates a list of {GContacts::Element}s based on the given XML from Google
    def initialize(data)
      data = data["feed"]

      if data["entry"].is_a?(Array)
        @entries = data["entry"].map {|entry| Element.new(entry)}
      else
        @entries = [Element.new(data["entry"])]
      end

      if data["link"]
        data["link"].each do |link|
          if link["@rel"] == "next"
            @next_uri = URI(link["@href"])
          elsif link["@rel"] == "previous"
            @previous_uri = URI(link["@href"])
          end
        end
      end

      @id, @updated, @title, @author = data["id"], data["updated"], data["title"], data["author"]
      @per_page, @start_index, @total_results = data["openSearch:itemsPerPage"].to_i, data["openSearch:startIndex"].to_i, data["openSearch:totalResults"].to_i
      @category = @entries.first.category
    end

    def each; @entries.each {|e| yield e} end
    def [](index); @entries[index] end
    def empty?; @entries.empty? end
    def length; @entries.length end

    alias size length
  end
end