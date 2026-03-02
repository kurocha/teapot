# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2026, by Samuel Williams.

require_relative "definition"

module Teapot
	class Project < Definition
		Author = Struct.new(:name, :email, :website)
		
		def initialize(context, package, name)
			super context, package, name
			
			@version = "0.0.0"
			@authors = []
		end
		
		def name
			if @title
				# Prefer title, it retains case.
				Build::Name.new(@title)
			else
				# Otherwise, if we don't have title, use the target name.
				Build::Name.from_target(@name)
			end
		end
		
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
		
		def add_author(name, options = {})
			@authors << Author.new(name, options[:email], options[:website])
		end
	end
end
