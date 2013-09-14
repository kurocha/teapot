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
	# Very similar to a set but uses a specific callback for object identity.
	class IdentitySet
		include Enumerable
		
		def initialize(contents = [], &block)
			@table = {}
			@identity = block
			
			contents.each do |object|
				add(object)
			end
		end
	
		def initialize_dup(other)
			@table = other.table.dup
		end
	
		attr :table
	
		def add(object)
			@table[@identity[object]] = object
		end
	
		alias << add
	
		def remove(object)
			@table.delete(@identity[object])
		end
	
		def include?(object)
			@table.include?(@identity[object])
		end
		
		def each(&block)
			@table.each_value(&block)
		end
	
		def size
			@table.size
		end
		
		def clear
			@table.clear
		end
		
		alias count size
	
		def to_s
			@table.to_s
		end
		
		def self.by_name(contents = [])
			self.new(contents, &:name)
		end
	end
	
	class Configuration < Definition
		Import = Struct.new(:name, :explicit, :options)
		
		DEFAULT_OPTIONS = {
			:import => true
		}
		
		def initialize(context, package, name, packages = [], options = nil)
			super context, package, name

			if options
				@options = options
			else
				@options = DEFAULT_OPTIONS.dup
			end

			@packages = IdentitySet.by_name(packages)
			@imports = IdentitySet.by_name

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
			return false if @imports.count == 0
			
			# Avoid loops in the dependency chain:
			imported = IdentitySet.new(&:name)
			
			# Enumerate all imports and attempt to resolve the packages:
			begin
				updated = false
				
				# Before trying to materialize, we should load all possible packages:
				@packages.each do |package|
					@context.load(package) rescue nil
				end
				
				imports = @imports
				@imports = IdentitySet.new(&:name)
				
				imports.each do |import|
					named_configuration = @context.configurations[import.name]

					# So we don't get into some crazy cycle:
					next if imported.include? import
					
					# It would be nice if we could detect cycles and issue an error to the user. However, sometimes the case above is not hit at the point where the cycle begins - it isn't clear at what point the user explicitly created a cycle, and what configuration actually ends up being imported a second time.
					
					if named_configuration && named_configuration != self
						# Mark this as resolved
						imported << import
						
						updated = self.merge(named_configuration, import.options) || updated
					else
						# It couldn't be resolved and hasn't already been resolved...
						@imports << import
					end
				end
			end while updated
			
			return true
		end
		
		# Merge an external configuration into this configuration. We won't override already defined packages.
		def merge(configuration, options)
			updated = false
			
			configuration.packages.each do |external_package|
				# The top level configuration will override packages that are defined by imported configurations. This is desirable behaviour, as it allows us to flatten the configuration but provide overrides if required.
				unless @packages.include? external_package
					options = options.merge(external_package.options)
					
					@packages << Package.new(packages_path + external_package.name, external_package.name, options)
					
					updated = true
				end
			end
			
			configuration.imports.each do |external_import|
				unless @imports.include? external_import
					options = options.merge(external_import.options)
					
					@imports << Import.new(external_import.name, external_import.explicit, options)
					
					updated = true
				end
			end
			
			return updated
		end
		
		def to_s
			"<#{self.class.name} #{@name.dump} visibility=#{@visibility}>"
		end
	end
end
