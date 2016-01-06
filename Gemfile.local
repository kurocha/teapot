source 'https://rubygems.org'

# Specify your gem's dependencies in teapot.gemspec
gemspec

group :development do
	gem 'pry'
	gem 'pry-coolline'
	
	gem 'build', path: '../build'
	gem 'build-environment', path: '../build-environment'
	gem 'build-files', path: '../build-files'
	gem 'build-graph', path: '../build-graph'
	gem 'build-makefile', path: '../build-makefile'
	
	gem 'process-daemon', path: '../process-daemon'
	gem 'process-group', path: '../process-group'
end

group :test do
	gem 'simplecov'
	gem 'coveralls', require: false
end
