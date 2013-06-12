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

require 'pathname'
require 'set'

require 'yaml/store'

require 'teapot/context'
require 'teapot/environment'
require 'teapot/commands'

require 'teapot/definition'

module Teapot
	class Configuration < Definition
		Import = Struct.new(:name, :options)
		
		def initialize(context, package, name, packages = Set.new, options = {})
			super context, package, name

			@options = options

			@packages = packages
			@imports = []

			@visibility = :private
		end

		# Controls how the configuration is exposed in the context.
		attr :visibility

		def public?
			@visibility == :public
		end

		def public!
			@visibility = :public
		end

		# Options used to bind packages to this configuration.
		attr :options

		# A list of packages which are required by this configuration.
		attr :packages

		# A list of other configurations to include when materialising the list of packages.
		attr :imports

		# Specifies that this configuration depends on an external package of some sort.
		def require(name, options = nil)
			options = options ? @options.merge(options) : @options.dup
			
			@packages << Package.new(packages_path + name.to_s, name, options)
		end

		# Specifies that this package will import additional configuration records from another definition.
		def import(name)
			@imports << Import.new(name, @options.dup)
		end

		# Require and import the named package.
		def import!(name, options = nil)
			require(name, options)
			import(name)
		end

		# Create a group for configuration options which will be only be active within the group block.
		def group
			options = @options.dup
			
			yield
			
			@options = options
		end

		# Set a configuration option.
		def []= key, value
			@options[key] = value
		end

		# Get a configuration option.
		def [] key
			@options[key]
		end

		# The path where packages will be located when fetched.
		def packages_path
			context.root + "teapot/packages/#{name}"
		end

		# The path where built products will be installed.
		def platforms_path
			context.root + "teapot/platforms/#{name}"
		end

		def lock_path
			context.root + "#{@name}-lock.yml"
		end

		def lock_store
			@lock_store ||= YAML::Store.new(lock_path.to_s)
		end

		# Load all packages defined by this configuration.
		def load_all
			@packages.each do |package|
				@context.load(package)
			end
		end
		
		# Conceptually, a configuration belongs to a package. Primarily, a configuration lists dependent packages, but this also includes itself as the dependencies are purely target based, e.g. this configuration has access to any targets exposed by its own package.
		def top!
			@packages << @package
		end

		# Process all import directives and return a new configuration based on the current configuration. Import directives bring packages and other import directives from the specififed configuration definition.
		def materialize
			# Potentially no materialization is required:
			return self if @imports.count == 0
			
			# Before trying to materialize, we should load all possible packages:
			@packages.each do |package|
				@context.load(package) rescue nil
			end
			
			# Create a new configuration which will represent the materialised version:
			configuration = self.class.new(@context, @package, @name, @packages.dup, @options.dup)
			
			# Enumerate all imports and attempt to resolve the packages:
			@imports.each do |import|
				named_configuration = @context.configurations[import.name]
				
				if named_configuration && named_configuration != self
					configuration.append(named_configuration.materialize, import.options)
				else
					# It couldn't be resolved...
					configuration.imports << import
				end
			end
			
			return configuration
		end
		
		def append(configuration, options)
			@packages += configuration.packages.collect do |package|
				package.dup.tap{|package| package.options = options.merge(package.options)}
			end
			
			@imports += configuration.imports.collect do |import|
				import.dup.tap{|import| import.options = options.merge(import.options)}
			end
		end
		
		def to_s
			"<#{self.class.name} #{@name.dump} visibility=#{@visibility}>"
		end
	end
end
