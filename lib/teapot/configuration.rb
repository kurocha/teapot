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

require 'teapot/context'
require 'teapot/environment'
require 'teapot/commands'

require 'teapot/definition'

module Teapot
	class Configuration < Definition
		Import = Struct.new(:name, :options)
		
		def initialize(context, package, name, packages = Set.new)
			super context, package, name

			@options = {}

			@packages = packages
			@imports = []
		end

		# Options used to bind packages to this configuration:
		attr :options

		# A list of packages which are required by this configuration:
		attr :packages

		# A list of other configurations to include when materialising the list of packages:
		attr :imports

		def import(name)
			@imports << Import.new(name, @options.dup)
		end

		def package(name, options = nil)
			options = options ? @options.merge(options) : @options.dup
			
			@packages << Package.new(packages_path + name.to_s, name, options)
		end

		def group
			options = @options.dup
			
			yield
			
			@options = options
		end

		def []= key, value
			@options[key] = value
		end

		def [] key
			@options[key]
		end

		def packages_path
			context.root + "teapot/packages/#{name}"
		end

		def platforms_path
			context.root + "teapot/platforms/#{name}"
		end

		def load_all
			@packages.each do |package|
				@context.load(package)
			end
		end
		
		# Conceptually, a configuration belongs to a package. Primarily, a configuration lists dependent packages, but this also includes itself as the dependencies are purely target based, e.g. this configuration has access to any targets exposed by its own package.
		def top!
			@packages << @package
		end
		
		def materialize
			# Potentially no materialization is required:
			return self if @imports.count == 0
			
			# Before trying to materialize, we should load all possible packages:
			@packages.each{|package| @context.load(package) rescue nil}
			
			# Create a new configuration which will represent the materialised version:
			configuration = self.class.new(@context, @package, @name, @packages.dup)
			
			# Enumerate all imports and attempt to resolve the packages:
			@imports.each do |import|
				resolved_configuration = @context.configuration_named(import.name)
				
				if resolved_configuration
					configuration.append(resolved_configuration, import.options)
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
	end
end
