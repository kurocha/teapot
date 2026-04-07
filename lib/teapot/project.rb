# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2026, by Samuel Williams.

require_relative "definition"

module Teapot
	# A project definition.
	class Project < Definition
		Author = Struct.new(:name, :email, :website)
		
		# Initialize a new project.
		# @parameter context [Context] The project context.
		# @parameter package [Package] The package.
		# @parameter name [String] The project name.
		def initialize(context, package, name)
			super context, package, name
			
			@version = "0.0.0"
			@authors = []
		end
		
		# Get the project name as a Build::Name object.
		# @returns [Build::Name] The project name.
		def name
			if @title
				# Prefer title, it retains case.
				Build::Name.new(@title)
			else
				# Otherwise, if we don't have title, use the target name.
				Build::Name.from_target(@name)
			end
		end
		
		# Make the project immutable after all packages and configurations have been loaded.
		def freeze
			@title.freeze
			@summary.freeze
			@license.freeze
			@website.freeze
			@version.freeze
			
			@authors.freeze
			
			super
		end
		
		attr_accessor :title
		attr_accessor :summary
		attr_accessor :license
		attr_accessor :website
		attr_accessor :version
		
		attr :authors
		
		# Add an author to the project.
		# @parameter name [String] The author name.
		# @parameter options [Hash] Author options (email, website).
		def add_author(name, options = {})
			@authors << Author.new(name, options[:email], options[:website])
		end
	end
end
