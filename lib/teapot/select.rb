# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require_relative "loader"
require_relative "package"

require "build/rulebook"
require "build/text/substitutions"
require "build/text/merge"

module Teapot
	class AlreadyDefinedError < StandardError
		def initialize(definition, previous)
			super "Definition #{definition.name} in #{definition.path} has already been defined in #{previous.path}!"
		end
		
		def self.check(definition, definitions)
			previous = definitions[definition.name]
			
			raise self.new(definition, previous) if previous
		end
	end
	
	# A selection is a specific view of the data exposed by the context at a specific point in time.
	class Select
		def initialize(context, configuration, names = [])
			@context = context
			@configuration = Configuration.new(context, configuration.package, configuration.name, [], **configuration.options)
			
			@targets = {}
			@configurations = {}
			@projects = {}
			
			@dependencies = []
			@selection = Set.new
			@resolved = Build::Dependency::Set.new
			@unresolved = Build::Dependency::Set.new
			
			load!(configuration, names)
			
			@chain = nil
		end
		
		attr :context
		attr :configuration
		
		attr :targets
		attr :projects
		
		# Alises as defined by Configuration#targets
		attr :aliases
		
		# All public configurations.
		attr :configurations
		
		attr :dependencies
		attr :selection
		
		attr :resolved
		attr :unresolved
		
		def chain
			@chain ||= Build::Dependency::Chain.expand(@dependencies, @targets.values, @selection)
		end
		
		def direct_targets(ordered)
			@dependencies.collect do |dependency|
				ordered.find{|(package, _)| package.provides? dependency}
			end.compact
		end
		
		private
		
		# Add a definition to the current context.
		def append definition
			case definition
			when Target
				AlreadyDefinedError.check(definition, @targets)
				@targets[definition.name] = definition
			when Configuration
				# We define configurations in two cases, if they are public, or if they are part of the root package of this context.
				if definition.public? or definition.package == @context.root_package
					AlreadyDefinedError.check(definition, @configurations)
					@configurations[definition.name] = definition
				end
			when Project
				AlreadyDefinedError.check(definition, @projects)
				@projects[definition.name] = definition
			end
		end
		
		def load_package!(package)
			begin
				script = @context.load(package)
				
				# Load the definitions into the current selection:
				script.defined.each do |definition|
					append(definition)
				end
				
				@resolved << package
			rescue MissingTeapotError, IncompatibleTeapotError
				# If the package doesn't exist or the teapot version is too old, it failed:
				@unresolved << package
			end
		end
		
		def load!(configuration, names)
			# Load the root package which makes all the named configurations and targets available.
			load_package!(@context.root_package)
			
			# Load all packages defined by this configuration.
			configuration.traverse(@configurations) do |configuration|
				@configuration.merge(configuration) do |package|
					# puts "Load package: #{package} from #{configuration}"
					load_package!(package)
				end
			end
			
			@configuration.freeze
			
			names.each do |name|
				if @targets.key? name
					@selection << name
				else
					@dependencies << name
				end
			end
		end
	end
end
