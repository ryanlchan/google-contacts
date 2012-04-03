$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "google-contacts"

RSpec.configure do |c|
  c.mock_with :rspec
end
