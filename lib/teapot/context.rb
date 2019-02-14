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

require_relative 'select'

module Teapot
	# A context represents a specific root package instance with a given configuration and all related definitions. A context is stateful in the sense that package selection is specialized based on #select and #dependency_chain. These parameters are usually set up initially as part of the context setup.
	class Context
		def initialize(root, **options)
			@root = Path[root]
			@options = options

			@configuration = nil
			@project = nil

			@loaded = {}

			load_root_package(**options)
		end

		attr :root
		attr :options

		# The primary configuration.
		attr :configuration

		# The primary project.
		attr :project

		def repository
			@repository ||= Rugged::Repository.new(@root.to_s)
		end
		
		def select(names = [], configuration = @configuration)
			Select.new(self, configuration, names)
		end

		def substitutions
			substitutions = Build::Text::Substitutions.new
			
			substitutions['TEAPOT_VERSION'] = Teapot::VERSION
			
			if @project
				name = @project.name
				
				# e.g. Foo Bar, typically used as a title, directory, etc.
				substitutions['PROJECT_NAME'] = name.text
				
				# e.g. FooBar, typically used as a namespace
				substitutions['PROJECT_IDENTIFIER'] = name.identifier
				
				# e.g. foo-bar, typically used for targets, executables
				substitutions['PROJECT_TARGET_NAME'] = name.target
				
				substitutions['LICENSE'] = @project.license
			end
			
			# The user's current name:
			substitutions['AUTHOR_NAME'] = repository.config['user.name']
			substitutions['AUTHOR_EMAIL'] = repository.config['user.email']
			
			current_date = Time.new
			substitutions['DATE'] = current_date.strftime("%-d/%-m/%Y")
			substitutions['YEAR'] = current_date.strftime("%Y")
			
			return substitutions
		end

		def load(package)
			if loader = @loaded[package]
				return loader.script unless loader.changed?
			end
			
			loader = Loader.new(self, package)
			
			@loaded[package] = loader
			
			return loader.script
		end
		
		# The root package is a special package which is used to load definitions from a given root path.
		def root_package
			@root_package ||= Package.new(@root, "root")
		end
		
		private
		
		def load_root_package(**options)
			# Load the root package:
			script = load(root_package)

			# Find the default configuration, if it exists:
			if configuration_name = options[:configuration]
				@configuration = @configurations[configuration_name]
			else
				@configuration = script.default_configuration
			end
			
			@project = script.default_project
			
			if @configuration.nil?
				raise ArgumentError.new("Could not load configuration: #{configuration_name.inspect}")
			end
		end
	end
end
