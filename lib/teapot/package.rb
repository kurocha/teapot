# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2026, by Samuel Williams.

require "build/files"
require "build/uri"

require_relative "definition"

module Teapot
	Path = Build::Files::Path
	
	class Package
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
		
		def local
			@options[:local].to_s
		end
		
		def local?
			@options.include?(:local)
		end
		
		def external?
			@options.include?(:source)
		end
		
		# The source uri from which this package would be cloned. Might be relative, in which case it's relative to the root of the context.
		def source_uri
			Build::URI[@options[:source]]
		end
		
		def external_url(root_path = nil)
			Build::URI[root_path] + source_uri + Build::URI[@uri]
		end
		
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
		
		def hash
			@path.hash
		end
		
		def eql?(other)
			@path.eql?(other.path)
		end
	end
end
