# frozen_string_literal: true

require_relative "lib/teapot/version"

Gem::Specification.new do |spec|
	spec.name = "teapot"
	spec.version = Teapot::VERSION
	
	spec.summary = "Teapot is a tool for managing cross-platform builds."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.metadata = {
		"documentation_uri" => "https://ioquatix.github.io/teapot/",
		"funding_uri" => "https://github.com/sponsors/ioquatix",
		"source_code_uri" => "https://github.com/ioquatix/teapot",
	}
	
	spec.files = Dir.glob(["{context,bin,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.executables = ["teapot"]
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "build", "~> 2.9"
	spec.add_dependency "build-dependency", "~> 1.6"
	spec.add_dependency "build-environment", "~> 1.10"
	spec.add_dependency "build-files", "~> 1.8"
	spec.add_dependency "build-files-monitor", "~> 0.4"
	spec.add_dependency "build-graph", "~> 2.3"
	spec.add_dependency "build-text", "~> 1.0"
	spec.add_dependency "build-uri", "~> 1.0"
	spec.add_dependency "console", "~> 1.0"
	spec.add_dependency "process-group", "~> 1.2"
	spec.add_dependency "pstore"
	spec.add_dependency "rugged", "~> 1.0"
	spec.add_dependency "samovar", "~> 2.0"
end
