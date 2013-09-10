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
	advanced dependency management via the Teapot file and is supported by
	the infusions ecosystem of packages and platform tooling.
	EOF
	spec.summary       = %q{Teapot is a tool for managing complex cross-platform builds.}
	spec.homepage      = "http://www.kyusu.org"
	spec.license       = "MIT"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.required_ruby_version = '>= 1.9.3'

	spec.add_dependency "rainbow"
	spec.add_dependency "rexec", "~> 1.6.0"
	spec.add_dependency "trollop"
	spec.add_dependency "facter"

	# This could be a good option in the future for teapot fetch:
	#spec.add_dependency "rugged"
end
