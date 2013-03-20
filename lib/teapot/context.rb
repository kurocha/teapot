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

require 'teapot/loader'
require 'teapot/package'

module Teapot
	TEAPOT_FILE = "teapot.rb"
	
	class Context
		def initialize(root, options = {})
			@root = Pathname(root)
			@options = options

			@selection = nil

			@targets = {}
			@generators = {}
			@configurations = {}

			@dependencies = []
			@selection = Set.new
			
			load(root_package)
		end

		attr :root

		attr :targets
		attr :generators
		attr :configurations

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

		def select(names)
			names.each do |name|
				if @targets.key? name
					@selection << name
				else
					@dependencies << name
				end
			end
		end
		
		attr :dependencies
		attr :selection
		
		def direct_targets(ordered)
			@dependencies.collect do |dependency|
				ordered.find{|(package, _)| package.provides? dependency}
			end.compact
		end
		
		def load(package)
			loader = Loader.new(self, package)
			
			path = (package.path + TEAPOT_FILE).to_s
			loader.load(path)
			
			if loader.version == nil
				raise IncompatibleTeapot.new("No version specified in #{path}!")
			end
			
			loader.defined
		end
		
		private
		
		# The root package is a special package which is used to load definitions from a given root path. It won't be included in any configuration by default.
		def root_package
			Package.new(@root, "local")
		end
	end
end
