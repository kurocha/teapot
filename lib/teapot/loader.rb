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

require_relative 'project'
require_relative 'target'
require_relative 'configuration'

require 'build/rule'
require 'build/name'
require 'build/files'

module Teapot
	# Cannot load packages newer than this.
	# Version 1.3: Added support for build-dependency library which allows options for `#depends`. The primary use case is private dependencies.
	# Version 2.0: Generators removed and refactored into build.
	# Version 2.3: Rework install_prefix -> build_prefix.
	LOADER_VERSION = "3.0"
	
	# Cannot load packages older than this.
	MINIMUM_LOADER_VERSION = "1.0"
	
	# The package relative path to the file to load:
	TEAPOT_FILE = 'teapot.rb'.freeze
	
	class IncompatibleTeapotError < StandardError
		def initialize(package, version)
			super "Unsupported teapot_version #{version} in #{package.path}!"
		end
		
		attr :version
	end
	
	class MissingTeapotError < StandardError
		def initialize(path)
			super "Could not read file at #{path}!"
		end
		
		attr :path
	end
	
	# The DSL exposed to the `teapot.rb` file.
	class Script
		Files = Build::Files
		Rule = Build::Rule
		
		def initialize(context, package, path = TEAPOT_FILE)
			@context = context
			@package = package
			
			@defined = []
			@version = nil
			
			@configurations = Build::Dependency::Set.new
			
			@default_project = nil
			@default_configuration = nil
			
			@mtime = nil
		end
		
		attr :context
		attr :package
		attr :defined
		attr :version
		
		attr :configurations
		
		attr :default_project
		attr :default_configuration
		
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
			
			@default_project = project
			@defined << project
		end
		
		def define_target(*args)
			target = Target.new(@context, @package, *args)
			
			yield target
			
			target.update_environments!
			
			@defined << target
		end
		
		def define_configuration(*args)
			configuration = Configuration.new(@context, @package, *args)

			yield configuration

			@default_configuration ||= configuration
			@defined << configuration
			@configurations << configuration
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
	end
	
	# Loads the teapot.rb script and can reload it if it was changed.
	class Loader
		def initialize(context, package, path = TEAPOT_FILE)
			@context = context
			@package = package
			
			@path = path
			@mtime = nil
			
			@script, @mtime = load!
		end
		
		attr :script
		
		def teapot_path
			@package.path + @path
		end
		
		def changed?
			File.mtime(teapot_path) > @mtime
		end
		
		def reload
			self.class.new(@context, @package, @path)
		end
		
		private
		
		# Load a teapot.rb file relative to the root of the @package.
		def load!(path = teapot_path)
			raise MissingTeapotError.new(path) unless File.exist?(path)
			
			script = Script.new(@context, @package)
			
			mtime = File.mtime(path)
			script.instance_eval(path.read, path.to_s)
			
			if script.version == nil
				raise IncompatibleTeapotError.new(@package, "<unspecified>")
			end
			
			return script, mtime
		end
	end
end
