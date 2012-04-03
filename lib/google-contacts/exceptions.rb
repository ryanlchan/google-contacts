module GContacts
  class MissingToken < RuntimeError; end

  class HTTPError < StandardError
    attr_reader :reply_code

    def initialize(msg, reply_code=nil)
      super(msg)
      @reply_code = reply_code
    end
  end

end