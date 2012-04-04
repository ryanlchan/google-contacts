module GContacts
  class List
    include Enumerable

    attr_reader :id, :updated, :title, :author, :per_page, :start_index, :total_results, :next_uri

    def initialize(data)
      data = data["feed"]

      type = data["category"]["@term"].split("#", 2).last
      if type == "contact"
        @entries = data["entry"].map {|entry| Element.new(entry)}
      else
        raise InvalidKind, "Google element of kind #{type} is not supported"
      end

      @id, @updated, @title, @author = data["id"], data["updated"], data["title"], data["author"]
      @per_page, @start_index, @total_results = data["openSearch:itemsPerPage"].to_i, data["openSearch:startIndex"].to_i, data["openSearch:totalResults"].to_i

      data["link"].each do |link|
        if link["@rel"] == "next"
          @next_uri = URI(link["@href"])
          break
        end
      end
    end

    def each; @entries.each {|e| yield e} end
    def [](index); @entries[index] end
  end
end