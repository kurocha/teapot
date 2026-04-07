# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2026, by Samuel Williams.

module Teapot
	# Base class for definitions (target, configuration, or project).
	class Definition
		# Initialize a new definition.
		# @parameter context [Context] The project context.
		# @parameter package [Package] The package.
		# @parameter name [String] The definition name.
		def initialize(context, package, name)
			@context = context
			@package = package
			
			@name = name
			
			@description = nil
		end
		
		# Make the definition immutable after it has been loaded from a teapot file.
		def freeze
			@name.freeze
			@description.freeze
			
			super
		end
		
		# @returns [String] The string representation.
		def inspect
			"\#<#{self.class.name} #{@name}>"
		end
		
		# The context in which the definition was loaded:
		attr :context
		
		# The package in which the definition was specified:
		attr :package
		
		# The name of the definition:
		attr :name
		
		# A textual description of the definition, possibly in markdown format:
		attr :description
		
		# Assign a description with automatic removal of common leading indentation.
		# @parameter text [String] The description text.
		def description=(text)
			if text =~ /^(\t+)/
				text = text.gsub(/#{$1}/, "")
			end
			
			@description = text
		end
		
		# The path that the definition is relative to:
		def path
			@package.path
		end
		
		# @returns [String] The string representation.
		def to_s
			"#<#{self.class} #{@name.dump}>"
		end
	end
end
