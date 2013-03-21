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

require 'teapot/target'
require 'teapot/generator'
require 'teapot/configuration'

require 'teapot/build'

module Teapot
	LOADER_VERSION = "0.7"
	MINIMUM_LOADER_VERSION = "0.6"
	
	class IncompatibleTeapotError < StandardError
		def initialize(version)
			super "Version #{version} isn't compatible with current loader! Minimum supported version: #{MINIMUM_LOADER_VERSION}; Current version: #{LOADER_VERSION}."
		end
	end
	
	class NonexistantTeapotError < StandardError
		def initialize(path)
			super "Could not load #{path}!"
		end
	end
	
	class Loader
		# Provides build_directory and build_external methods
		include Build::Helpers
		
		def initialize(context, package)
			@context = context
			@package = package
			
			@defined = []
			@version = nil
		end
		
		attr :context
		
		attr :package
		attr :defined
		attr :version
		
		def required_version(version)
			version = version[0..2]
			
			if version >= MINIMUM_LOADER_VERSION && version <= LOADER_VERSION
				@version = version
			else
				raise IncompatibleTeapotError.new(version)
			end
		end

		def define_target(*args)
			target = Target.new(@context, @package, *args)

			yield target

			@defined << target
		end
		
		def define_generator(*args)
			generator = Generator.new(@context, @package, *args)

			yield generator

			@defined << generator
		end
		
		def define_configuration(*args)
			configuration = Configuration.new(@context, @package, *args)

			yield configuration

			configuration.packages << @package

			@defined << configuration
		end
		
		def load(path)
			raise NonexistantTeapotError.new(path) unless File.exist?(path)
			
			self.instance_eval(File.read(path), path)
		end
	end
end
