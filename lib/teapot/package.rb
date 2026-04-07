# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2026, by Samuel Williams.

require "build/files"
require "build/uri"

require_relative "definition"

module Teapot
	Path = Build::Files::Path
	
	# A package in the dependency graph.
	class Package
		# Initialize a new package.
		# @parameter path [String] The package path.
		# @parameter name [String | Symbol] The package name or URI.
		# @parameter options [Hash] Additional options.
		def initialize(path, name, options = {})
			# The path where the package is (or will be) located:
			@path = Path[path]
			
			# Get the name of the package from the options, if provided:
			if options[:name]
				@name = options[:name]
			end
			
			if Symbol === name
				# If the name argument was symbolic, we convert it into a string, and use it for both the uri and the name itself:
				@uri = name.to_s
				@name ||= @uri
			else
				# Otherwise, we assume a path may have been given, and use that instead:
				@name ||= File.basename(name)
				@uri = name
			end
			
			# Copy the options provided:
			@options = options
		end
		
		# Make the package immutable to prevent modification after it's been loaded and processed.
		def freeze
			@path.freeze
			@name.freeze
			@uri.freeze
			@options.freeze
			
			super
		end
		
		attr :name
		attr :path
		
		attr :uri
		attr_accessor :options
		
		# The local filesystem path if this package is linked rather than cloned.
		# @returns [String] The local path.
		def local
			@options[:local].to_s
		end
		
		# Whether this package is linked from a local path instead of being cloned from a remote repository.
		# @returns [Boolean] True if local.
		def local?
			@options.include?(:local)
		end
		
		# Whether this package should be cloned from an external source repository.
		# @returns [Boolean] True if external.
		def external?
			@options.include?(:source)
		end
		
		# The source uri from which this package would be cloned. Might be relative, in which case it's relative to the root of the context.
		def source_uri
			Build::URI[@options[:source]]
		end
		
		# Construct the full URL from which this package should be cloned, combining the root path, source URI, and package URI.
		# @parameter root_path [String | Nil] The root path.
		# @returns [Build::URI] The external URL.
		def external_url(root_path = nil)
			Build::URI[root_path] + source_uri + Build::URI[@uri]
		end
		
		# @returns [String] The string representation.
		def to_s
			if self.local?
				"links #{@name} from #{self.local}"
			elsif self.external?
				"clones #{@name} from #{self.external_url}"
			else
				"references #{@name} from #{@path}"
			end
		end
		
		# Package may be used as hash key / in a set:
		
		# Packages are hashed by path for use as hash keys and set members.
		# @returns [Integer] The hash code.
		def hash
			@path.hash
		end
		
		# Packages are considered equal if they have the same path.
		# @parameter other [Package] The other package.
		# @returns [Boolean] True if equal.
		def eql?(other)
			@path.eql?(other.path)
		end
	end
end
