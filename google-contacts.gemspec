$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
require "google-contacts/version"

Gem::Specification.new do |s|
  s.name        = "google-contacts"
  s.version     = GContacts::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Zachary Anker"]
  s.email       = ["zach.anker@gmail.com"]
  s.homepage    = "http://github.com/Placester/google-contacts"
  s.summary     = "Google Contacts v3 library"
  s.description = "Helps manage both the importing and exporting of Google Contacts data"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "google-contacts"

  s.add_runtime_dependency "nokogiri", "~>1.5.0"
  s.add_runtime_dependency "nori", "~>1.1.0"

  s.add_development_dependency "oauth2", "~>0.5.0"
  s.add_development_dependency "signet", "~>0.3.0"
  s.add_development_dependency "rspec", "~>2.8.0"
  s.add_development_dependency "guard-rspec", "~>0.6.0"

  s.files        = Dir.glob("lib/**/*") + %w[GPL-LICENSE MIT-LICENSE README.md CHANGELOG.md Rakefile]
  s.require_path = "lib"
end