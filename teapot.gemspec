# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'teapot/version'

Gem::Specification.new do |gem|
	gem.name          = "teapot"
	gem.version       = Teapot::VERSION
	gem.authors       = ["Samuel Williams"]
	gem.email         = ["samuel.williams@oriontransfer.co.nz"]
	gem.description   = <<-EOF
	Teapot is a tool for managing complex cross-platform builds. It provides
	advanced dependency management via the Teapot file and is supported by
	the infusions ecosystem of packages and platform tooling.
	EOF
	gem.summary       = %q{Teapot is a tool for managing complex cross-platform builds.}
	gem.homepage      = ""

	gem.files         = `git ls-files`.split($/)
	gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
	gem.require_paths = ["lib"]
	
	gem.required_ruby_version = '>= 1.9.3'
	
	gem.add_dependency "rainbow"
	gem.add_dependency "rexec"
	gem.add_dependency "trollop"
	gem.add_dependency "facter"
end
