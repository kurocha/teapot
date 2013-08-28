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

require 'teapot/project'
require 'teapot/target'
require 'teapot/generator'
require 'teapot/configuration'
require 'teapot/rule'

require 'teapot/name'
require 'teapot/build'

module Teapot
	LOADER_VERSION = "0.9.6"
	MINIMUM_LOADER_VERSION = "0.8"
	
	class IncompatibleTeapotError < StandardError
		def initialize(package, version)
			super "Unsupported teapot_version #{version} in #{package.path}!"
		end
		
		attr :version
	end
	
	class NonexistantTeapotError < StandardError
		def initialize(path)
			super "Could not read file at #{path}!"
		end
		
		attr :path
	end
	
	class Loader
		class Definitions < Array
			def default_configuration
				find{|definition| Configuration === definition}
			end
		end
		
		# Provides build_directory and build_external methods
		include Build::Helpers
		
		# Provides run_executable and other related methods.
		include Commands::Helpers
		
		def initialize(context, package)
			@context = context
			@package = package

			@defined = Definitions.new
			@version = nil
		end

		attr :context
		attr :package
		attr :defined
		attr :version

		def teapot_version(version)
			version = version[0..2]
			
			if version >= MINIMUM_LOADER_VERSION && version <= LOADER_VERSION
				@version = version
			else
				raise IncompatibleTeapotError.new(package, version)
			end
		end

		alias required_version teapot_version

		def define_project(*args)
			project = Project.new(@context, @package, *args)
			
			yield project
			
			@defined << project
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

			configuration.top!

			yield configuration

			@defined << configuration
		end

		def define_rule(*args)
			rule = Rule.new(@context, @package, *args)

			yield rule

			@defined << rule
		end

		# Checks the host patterns and executes the block if they match.
		def host(*args, &block)
			name = @context.options[:host_platform] || RUBY_PLATFORM
			
			if block_given?
				if args.find{|arg| arg === name}
					yield
				end
			else
				name
			end
		end

		# Load a teapot.rb file relative to the root of the @package.
		def load(path)
			absolute_path = @package.path + path

			raise NonexistantTeapotError.new(absolute_path) unless File.exist?(absolute_path)

			self.instance_eval(absolute_path.read, absolute_path.to_s)
			
			if @version == nil
				raise IncompatibleTeapotError.new(@package, "<unspecified>")
			end
		end
	end
end
