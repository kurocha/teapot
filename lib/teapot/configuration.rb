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

require_relative 'identity_set'
require_relative 'definition'

module Teapot
	# A configuration represents a mapping between package/dependency names and actual source locations. Usually, there is only one configuration, but in some cases it is useful to have more than one, e.g. one for local development using local source code, one for continuous integration, and one for deployment.
	class Configuration < Definition
		Import = Struct.new(:name, :explicit, :options)
		
		DEFAULT_OPTIONS = {
			:import => true
		}.freeze
		
		def initialize(context, package, name, packages = [], **options)
			super context, package, name

			@options = DEFAULT_OPTIONS.merge(options)

			@packages = IdentitySet.new(packages)
			@imports = IdentitySet.new

			@visibility = :private

			# A list of named targets for specific purposes:
			@targets = Hash.new{|hash,key| hash[key] = Array.new}
		end

		def freeze
			return if frozen?
			
			@options.freeze
			@packages.freeze
			@imports.freeze
			@visibility.freeze
			
			@targets.default = [].freeze
			@targets.freeze
			
			super
		end

		# Controls how the configuration is exposed in the context.
		attr :visibility

		def public?
			@visibility == :public
		end

		def public!
			@visibility = :public
		end

		# A table of named targets for specific purposes.
		attr :targets

		# Options used to bind packages to this configuration.
		attr :options

		# A list of packages which are required by this configuration.
		attr :packages

		# A list of other configurations to include when materialising the list of packages.
		attr :imports

		# Specifies that this configuration depends on an external package of some sort.
		def require(name, **options)
			options = @options.merge(options)
			
			@packages << Package.new(packages_path + name.to_s, name, options)
			
			if options[:import] == true
				import(name, false)
			elsif String === options[:import]
				import(options[:import])
			end
		end

		# Specifies that this package will import additional configuration records from another definition.
		def import(name, explicit = true)
			@imports << Import.new(name, explicit, @options.dup)
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
			YAML::Store.new(lock_path.to_s)
		end

		def to_s
			"#<#{self.class} #{@name.dump} visibility=#{@visibility}>"
		end

		# Process all import directives and return a new configuration based on the current configuration. Import directives bring packages and other import directives from the specififed configuration definition.
		def traverse(configurations, imported = IdentitySet.new, &block)
			yield self # Whatever happens here, should ensure that...
			
			@imports.each do |import|
				# So we don't get into some crazy cycle:
				next if imported.include?(import)
				
				# Mark it as being imported:
				imported << import
				
				# ... by here, the configuration is available:
				if configuration = configurations[import.name]
					configuration.traverse(configurations, imported, &block)
				end
			end
		end
		
		# Merge an external configuration into this configuration. We won't override already defined packages.
		def merge(configuration)
			configuration.packages.each do |package|
				# The top level configuration will override packages that are defined by imported configurations. This is desirable behaviour, as it allows us to flatten the configuration but provide overrides if required.
				unless @packages.include? package
					package = Package.new(packages_path + package.name, package.name, @options.merge(package.options))
					
					@packages << package
					
					yield package
				end
			end
			
			configuration.imports.each do |import|
				unless @imports.include? import
					@imports << Import.new(import.name, import.explicit, @options.merge(import.options))
				end
			end
			
			configuration.targets.each do |key, value|
				@targets[key] += value
			end
			
			return self
		end
	end
end
