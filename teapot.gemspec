# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'teapot/version'

Gem::Specification.new do |spec|
	spec.name          = "teapot"
	spec.version       = Teapot::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.description   = <<-EOF
	Teapot is a tool for managing complex cross-platform builds. It provides
	advanced package-based dependency management with a single configuration file
	per project. It can fetch, list, build, visualise and create projects, and
	has been designed from the ground up to support collaborative decentralised
	development.
	EOF
	spec.summary       = %q{Teapot is a tool for managing complex cross-platform builds.}
	spec.homepage      = "http://www.kyusu.org"
	spec.license       = "MIT"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]
	
	spec.required_ruby_version = '>= 2.0'
	
	spec.add_dependency "rainbow", "~> 2.0.0"
	spec.add_dependency "trollop", "~> 2.0"
	
	spec.add_dependency "system", "~> 0.1.3"
	
	spec.add_dependency "graphviz", "~> 0.0.2"
	
	spec.add_dependency "build-files", "~> 0.2.7"
	spec.add_dependency "build-graph", "~> 0.3.5"
	spec.add_dependency "build-makefile", "~> 0.2.0"
	
	spec.add_dependency "process-daemon", "~> 0.5.5"
	spec.add_dependency "process-group", "~> 0.2.1"
	
	# This could be a good option in the future for teapot fetch:
	#spec.add_dependency "rugged"
	
	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.0.0"
	spec.add_development_dependency "rake"
end
