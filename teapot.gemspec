# frozen_string_literal: true

require_relative "lib/teapot/version"

Gem::Specification.new do |spec|
	spec.name = "teapot"
	spec.version = Teapot::VERSION
	
	spec.summary = "Teapot is a tool for managing complex cross-platform builds."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "http://www.teapot.nz"
	
	spec.files = Dir.glob('{bin,lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.executables = ["teapot"]
	
	spec.required_ruby_version = ">= 2.1.0"
	
	spec.add_dependency "build", "~> 2.4"
	spec.add_dependency "build-dependency", "~> 1.4"
	spec.add_dependency "build-environment", "~> 1.10"
	spec.add_dependency "build-files", "~> 1.8"
	spec.add_dependency "build-files-monitor", "~> 0.2.0"
	spec.add_dependency "build-text", "~> 1.0"
	spec.add_dependency "build-uri", "~> 1.0"
	spec.add_dependency "console", "~> 1.0"
	spec.add_dependency "graphviz", "~> 1.0"
	spec.add_dependency "process-group", "~> 1.2"
	spec.add_dependency "rugged", "~> 1.0"
	spec.add_dependency "samovar", "~> 2.0"
	
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "rake"
	spec.add_development_dependency "rspec", "~> 3.6"
end
