module GContacts
  module Client
    class Contact < Base
      def initialize(http, *args)
        super
        @uris = {:all => URI("#{DATA_URL}/m8/feeds/contacts/default/full"), :post => URI("#{DATA_URL}/m8/feeds/contacts/default/full"), :batch => URI("#{DATA_URL}/m8/feeds/contacts/default/batch")}
      end
    end
  end
end