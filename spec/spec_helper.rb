$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "google-contacts"
require "oauth2"
require "signet"

RSpec.configure do |c|
  c.mock_with :rspec
end
