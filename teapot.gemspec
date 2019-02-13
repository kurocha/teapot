
require_relative 'lib/teapot/version'

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
	spec.homepage      = "http://www.teapot.nz"
	spec.license       = "MIT"
	
	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]
	
	spec.required_ruby_version = '>= 2.1.0'
	
	spec.add_dependency "rainbow", "~> 2.0"
	
	spec.add_dependency "graphviz", "~> 1.0"
	
	spec.add_dependency "rugged"
	
	spec.add_dependency "build", "~> 2.0"
	spec.add_dependency "build-files", "~> 1.3"
	spec.add_dependency "build-dependency", "~> 1.1"
	spec.add_dependency "build-uri", "~> 1.0"
	spec.add_dependency "build-text", "~> 1.0"
	
	spec.add_dependency "samovar", "~> 1.7"
	
	spec.add_development_dependency "covered"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "rspec", "~> 3.6"
	spec.add_development_dependency "rake"
end
