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
		def initialize(context, package, name)
			super context, package, name

			@options = {}

			@packages = Set.new
			@imports = []
			
			top!
		end

		# Options used to bind packages to this configuration:
		attr :options

		# A list of packages which are required by this configuration:
		attr :packages

		# A list of other configurations to include when materialising the list of packages:
		attr :imports

		def import(name)
			@imports << name
		end

		def package(name, options = @options)
			@packages << Package.new(packages_path + name.to_s, name, options.dup)
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
		
		def top!
			@packages << @package
		end
		
		def materialize
			# Potentially no materialization is required:
			return self if @imports.count == 0
			
			# Before trying to materialize, we should load all possible packages:
			@packages.each{|package| @context.load(package) rescue nil}
			
			# Create a new configuration which will represent the materialised version:
			configuration = self.class.new(@context, @package, @name)
			
			# Append all current packages to the new package:
			configuration.append(self)
			
			# Enumerate all imports and attempt to resolve the packages:
			@imports.each do |name|
				resolved_configuration = @context.configuration_named(name)
				
				if resolved_configuration
					configuration.append(resolved_configuration)
				else
					# It couldn't be resolved...
					configuration.imports << name
				end
			end
			
			return configuration
		end
		
		def append(configuration)
			@packages += configuration.packages
		end
	end
end
