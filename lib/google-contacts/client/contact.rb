module GContacts
  module Client
    class Contact < Base
      def initialize(http, *args)
        super
        @uris = {:all => "/m8/feeds/contacts/default/full", :post => "/m8/feeds/contacts/default/full", :batch => "/m8/feeds/contacts/default/batch"}
      end
    end
  end
end