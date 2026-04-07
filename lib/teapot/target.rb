# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2026, by Samuel Williams.

require "pathname"
require "build/dependency"
require_relative "definition"

require "build/environment"
require "build/rulebook"

module Teapot
	# Raised during build operations.
	class BuildError < StandardError
	end
	
	# A build target.
	class Target < Definition
		include Build::Dependency
		
		# Initialize a new target.
		def initialize(*)
			super
			
			@build = nil
		end
		
		# Make the target immutable after it has been completely defined with dependencies and build rules.
		def freeze
			return self if frozen?
			
			@build.freeze
			
			super
		end
		
		# Define the build block for this target.
		# @parameter block [Proc | Nil] The build block.
		# @returns [Proc | Nil] The build block.
		def build(&block)
			if block_given?
				@build = block
			end
			
			return @build
		end
		
		# Update environments with the build block.
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
