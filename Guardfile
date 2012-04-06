guard("rspec", :all_after_pass => false, :cli => "--fail-fast --color") do
  watch(%r{^spec/lib/.+_spec\.rb$})
  watch(%r{^lib/google\-contacts/(.+)\.rb$}) {|match| "spec/lib/#{match[1]}_spec.rb"}
end