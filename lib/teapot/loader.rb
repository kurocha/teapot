# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2026, by Samuel Williams.

require_relative "project"
require_relative "target"
require_relative "configuration"

require "build/rule"
require "build/name"
require "build/files"

module Teapot
	# Cannot load packages newer than this.
	# Version 1.3: Added support for build-dependency library which allows options for `#depends`. The primary use case is private dependencies.
	# Version 2.0: Generators removed and refactored into build.
	# Version 2.3: Rework install_prefix -> build_prefix.
	LOADER_VERSION = "3.0"
	
	# Cannot load packages older than this.
	MINIMUM_LOADER_VERSION = "1.0"
	
	# The package relative path to the file to load:
	TEAPOT_FILE = "teapot.rb".freeze
	
	# Raised when a teapot file requires an incompatible version.
	class IncompatibleTeapotError < StandardError
		# @parameter package [Package] The package.
		# @parameter version [String] The version.
		def initialize(package, version)
			super "Unsupported teapot_version #{version} in #{package.path}!"
		end
		
		attr :version
	end
	
	# Raised when a teapot file cannot be found.
	class MissingTeapotError < StandardError
		# @parameter path [String] The file path.
		def initialize(path)
			super "Could not read file at #{path}!"
		end
		
		attr :path
	end
	
	# The DSL exposed to the `teapot.rb` file.
	class Script
		Files = Build::Files
		Rule = Build::Rule
		
		# Initialize a new script.
		# @parameter context [Context] The project context.
		# @parameter package [Package] The package.
		# @parameter path [String] The teapot file path.
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
		
		# Specify the minimum required teapot gem version for compatibility checks.
		# @parameter version [String] The required version.
		def teapot_version(version)
			version = version[0..2]
			
			if version >= MINIMUM_LOADER_VERSION && version <= LOADER_VERSION
				@version = version
			else
				raise IncompatibleTeapotError.new(package, version)
			end
		end
		
		alias required_version teapot_version
		
		# Define a new project.
		# @parameter arguments [Array] The definition arguments.
		def define_project(*arguments, **options)
			project = Project.new(@context, @package, *arguments, **options)
			
			yield project
			
			@default_project = project
			@defined << project
		end
		
		# Define a new target.
		# @parameter arguments [Array] The definition arguments.
		def define_target(*arguments, **options)
			target = Target.new(@context, @package, *arguments, **options)
			
			yield target
			
			target.update_environments!
			
			@defined << target
		end
		
		# Define a new configuration.
		# @parameter arguments [Array] The definition arguments.
		def define_configuration(*arguments, **options)
			configuration = Configuration.new(@context, @package, *arguments, **options)
			
			yield configuration
			
			@default_configuration ||= configuration
			@defined << configuration
			@configurations << configuration
		end
		
		# Checks the host patterns and executes the block if they match.
		def host(*arguments, **options, &block)
			name = @context.options[:host_platform] || RUBY_PLATFORM
			
			if block_given?
				if arguments.find{|argument| argument === name}
					yield
				end
			else
				name
			end
		end
	end
	
	# Loads the teapot.rb script and can reload it if it was changed.
	class Loader
		# Initialize a new loader.
		# @parameter context [Context] The project context.
		# @parameter package [Package] The package.
		# @parameter path [String] The teapot file path.
		def initialize(context, package, path = TEAPOT_FILE)
			@context = context
			@package = package
			
			@path = path
			@mtime = nil
			
			@script, @mtime = load!
		end
		
		attr :script
		
		# The absolute path to the teapot.rb file for this package.
		# @returns [Build::Files::Path] The teapot file path.
		def teapot_path
			@package.path + @path
		end
		
		# Whether the teapot file has been modified since it was loaded.
		# @returns [Boolean] True if changed.
		def changed?
			File.mtime(teapot_path) > @mtime
		end
		
		# Reload the loader with fresh data.
		# @returns [Loader] A new loader instance.
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
