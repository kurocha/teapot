# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2026, by Samuel Williams.

require "pathname"
require "build/dependency"
require_relative "definition"

require "build/environment"
require "build/rulebook"

module Teapot
	class BuildError < StandardError
	end
	
	class Target < Definition
		include Build::Dependency
		
		def initialize(*)
			super
			
			@build = nil
		end
		
		def freeze
			return self if frozen?
			
			@build.freeze
			
			super
		end
		
		def build(&block)
			if block_given?
				@build = block
			end
			
			return @build
		end
		
		def update_environments!
			return unless @build
			
			self.provisions.each do |key, provision|
				build = @build
				original = provision.value
				
				wrapper = proc do |*arguments|
					self.instance_exec(*arguments, &original) if original
					self.instance_exec(*arguments, &build) if build
				end
				
				provision.value = wrapper
			end
			
			@build = nil
		end
	end
end
