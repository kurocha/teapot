# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2026, by Samuel Williams.

require_relative "select"

module Teapot
	# A context represents a specific root package instance with a given configuration and all related definitions. A context is stateful in the sense that package selection is specialized based on #select and #dependency_chain. These parameters are usually set up initially as part of the context setup.
	class Context
		# Initialize a new context.
		# @parameter root [String] The root path.
		def initialize(root, **options)
			@root = Path[root]
			@options = options
			
			@configuration = nil
			@project = nil
			
			@loaded = {}
			
			load_root_package(**options)
		end
		
		attr :root
		attr :options
		
		# The primary configuration.
		attr :configuration
		
		# The primary project.
		attr :project
		
		# Discover and open the git repository for this context's root directory.
		# @returns [Rugged::Repository] The git repository.
		def repository
			@repository ||= Rugged::Repository.discover(@root.to_s)
		end
		
		# Create a selection that resolves dependencies and loads definitions for the specified targets or configurations.
		# @parameter names [Array | Nil] The names to select.
		# @parameter configuration [Configuration] The configuration to use.
		# @returns [Select] The selection.
		def select(names = nil, configuration = @configuration)
			Select.new(self, configuration, names || [])
		end
		
		# Get substitutions for template generation.
		# @returns [Build::Text::Substitutions] The substitutions.
		def substitutions
			substitutions = Build::Text::Substitutions.new
			
			substitutions["TEAPOT_VERSION"] = Teapot::VERSION
			
			if @project
				name = @project.name
				
				# e.g. Foo Bar, typically used as a title, directory, etc.
				substitutions["PROJECT_NAME"] = name.text
				
				# e.g. FooBar, typically used as a namespace
				substitutions["PROJECT_IDENTIFIER"] = name.identifier
				
				# e.g. foo-bar, typically used for targets, executables
				substitutions["PROJECT_TARGET_NAME"] = name.target
				
				# e.g. foo_bar, typically used for variables.
				substitutions["PROJECT_VARIABLE_NAME"] = name.key
				
				substitutions["LICENSE"] = @project.license
			end
			
			# The user's current name:
			substitutions["AUTHOR_NAME"] = repository.config["user.name"]
			substitutions["AUTHOR_EMAIL"] = repository.config["user.email"]
			
			current_date = Time.new
			substitutions["DATE"] = current_date.strftime("%-d/%-m/%Y")
			substitutions["YEAR"] = current_date.strftime("%Y")
			
			return substitutions
		end
		
		# Load a package from its teapot.rb, tracking loaded packages to prevent duplicates.
		# @parameter package [Package] The package to load.
		# @returns [Script] The loaded script.
		def load(package)
			if loader = @loaded[package]
				return loader.script unless loader.changed?
			end
			
			loader = Loader.new(self, package)
			
			@loaded[package] = loader
			
			return loader.script
		end
		
		# The root package is a special package which is used to load definitions from a given root path.
		def root_package
			@root_package ||= Package.new(@root, "root")
		end
		
		private
		
		def load_root_package(**options)
			# Load the root package:
			script = load(root_package)
			
			# Find the default configuration, if it exists:
			if configuration_name = options[:configuration]
				@configuration = script.configurations[configuration_name]
			else
				@configuration = script.default_configuration
			end
			
			@project = script.default_project
			
			if @configuration.nil?
				raise ArgumentError.new("Could not load configuration: #{configuration_name.inspect}")
			end
		end
	end
end
