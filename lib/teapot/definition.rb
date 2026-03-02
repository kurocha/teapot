# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2026, by Samuel Williams.

module Teapot
	class Definition
		def initialize(context, package, name)
			@context = context
			@package = package
			
			@name = name
			
			@description = nil
		end
		
		def freeze
			@name.freeze
			@description.freeze
			
			super
		end
		
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
		
		def to_s
			"#<#{self.class} #{@name.dump}>"
		end
	end
end
