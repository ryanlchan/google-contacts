guard("rspec", :all_after_pass => false, :cli => "--fail-fast --color") do
  watch(%r{^spec/lib/.+_spec\.rb$})
  watch(%r{^lib/google\-contacts/(.+)\.rb$}) {|match| "spec/#{match[1]}_spec.rb"}
  watch(%r{^lib/google\-contacts/client/base\.rb$}) { ["spec/lib/client/contact_spec.rb"] }
end