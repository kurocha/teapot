# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'pathname'

require 'teapot/context'
require 'teapot/environment'
require 'teapot/commands'

module Teapot
	class Config
		include Dependency
		
		class Package
			def initialize(config, name, options = {})
				@config = config
				
				if options[:name]
					@name = options[:name]
				end
				
				if Symbol === name
					@uri = name.to_s
					@name ||= @uri
				else
					@name ||= File.basename(name)
					@uri = name
				end
				
				@options = options
				@global = Environment.new
			end
			
			attr :name
			attr :uri
			attr :options
			attr :global
			
			def relative_url(base_uri)
				source_uri = URI(@uri)

				unless source_uri.absolute?
					source_uri = base_uri + source_uri
				end
		
				# Git can't handle the default formatting that Ruby uses for file URIs.
				if source_uri.scheme == "file"
					source_uri = "file://" + source_uri.path
				end
				
				return source_uri
			end
			
			def local?
				@options.key? :local
			end
			
			def loader_path
				"teapot.rb"
			end
			
			def path
				@config.packages_path + @name
			end
			
			def to_s
				"<#{@name}>"
			end
		end
		
		def initialize(root, options = {})
			@root = Pathname.new(root)
			@options = options

			@packages = []

			@environment = Environment.new
		end

		def name
			:config
		end

		attr :root
		attr :packages
		attr :options

		attr :environment

		def packages_path
			@root + (@options[:packages_path] || "packages")
		end
		
		def platforms_path
			@root + (@options[:platforms_path] || "platforms")
		end
		
		def host(*args, &block)
			name = @options[:host_platform] || RUBY_PLATFORM
			
			if block_given?
				if args.find{|arg| arg === name}
					yield
				end
			else
				name
			end
		end
		
		attr :options
		attr :packages

		def source(path)
			@options[:source] = path
		end

		def package(name, options = {})
			@packages << Package.new(self, name, options)
		end

		def load(teapot_path)
			instance_eval File.read(teapot_path), teapot_path
		end

		def self.load(root, options = {})
			config = new(root, options)
			
			yield config if block_given?
			
			teapot_path = File.join(root, "Teapot")
			config.load(teapot_path) if File.exist? teapot_path
			
			return config
		end
		
		def self.load_default(root = Dir.getwd, options = {})
			# Load project specific Teapot file
			load(root, options) do |config|
				user_path = File.expand_path("~/.Teapot")
				
				if File.exist? user_path
					config.load(user_path)
				end
			end
		end
	end
end
