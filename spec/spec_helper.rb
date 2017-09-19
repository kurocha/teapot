
if ENV['COVERAGE'] || ENV['TRAVIS']
	begin
		require 'simplecov'
		
		SimpleCov.start do
			add_filter "/spec/"
		end
		
		if ENV['TRAVIS']
			require 'coveralls'
			Coveralls.wear!
		end
	rescue LoadError
		warn "Could not load simplecov: #{$!}"
	end
end

require "bundler/setup"
require "teapot"
require 'pry'

RSpec.shared_context Teapot::Context do
	let(:root) {Build::Files::Path[__dir__] + 'context'}
	let(:context) {Teapot::Context.new(root, load_root: false)}
end

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
