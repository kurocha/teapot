# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'teapot/loader'
require 'teapot/package'

module Teapot
	TEAPOT_FILE = "teapot.rb"
	DEFAULT_CONFIGURATION_NAME = 'default'

	class AlreadyDefinedError < StandardError
		def initialize(definition, previous)
			super "Definition #{definition.name} in #{definition.path} has already been defined in #{previous.path}!"
		end

		def self.check(definition, definitions)
			previous = definitions[definition.name]

			raise new(definition, previous) if previous
		end
	end

	class Context
		def initialize(root, options = {})
			@root = Pathname(root)
			@options = options

			@selection = nil

			@targets = {}
			@generators = {}
			@configurations = {}

			@dependencies = []
			@selection = Set.new

			@loaded = {}

			defined = load(root_package)

			# Find the default configuration, if it exists:
			@default_configuration = defined.find{|definition| Configuration === definition}
		end

		attr :root
		attr :options

		attr :targets
		attr :generators
		attr :configurations

		def select(names)
			names.each do |name|
				if @targets.key? name
					@selection << name
				else
					@dependencies << name
				end
			end
		end

		attr :dependencies
		attr :selection

		def direct_targets(ordered)
			@dependencies.collect do |dependency|
				ordered.find{|(package, _)| package.provides? dependency}
			end.compact
		end

		def << definition
			case definition
			when Target
				AlreadyDefinedError.check(definition, @targets)

				@targets[definition.name] = definition
			when Generator
				AlreadyDefinedError.check(definition, @generators)

				@generators[definition.name] = definition
			when Configuration
				# The root package implicitly defines the default configuration.
				if definition.name == DEFAULT_CONFIGURATION_NAME
					raise AlreadyDefinedError.new(definition, root_package)
				end

				AlreadyDefinedError.check(definition, @configurations)

				@configurations[definition.name] = definition
			end
		end

		def load(package)
			# In certain cases, a package record might be loaded twice. This typically occurs when multiple configurations are loaded in the same context, or if a package has already been loaded (as is typical with the root package).
			@loaded.fetch(package) do
				loader = Loader.new(self, package)

				loader.load(TEAPOT_FILE)

				if loader.version == nil
					raise IncompatibleTeapot.new("No version specified in #{path}!")
				end

				# Load the definitions into the current context:
				loader.defined.each do |definition|
					self << definition
				end

				# Save the definitions per-package:
				@loaded[package] = loader.defined
			end
		end

		attr :default_configuration

		def configuration_named(name)
			if name == DEFAULT_CONFIGURATION_NAME
				return @default_configuration
			else
				return @configurations[name]
			end
		end
		
		private

		# The root package is a special package which is used to load definitions from a given root path.
		def root_package
			@root_package ||= Package.new(@root, "root")
		end
	end
end
