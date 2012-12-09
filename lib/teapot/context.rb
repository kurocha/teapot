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
require 'rainbow'

require 'teapot/target'

module Teapot
	LOADER_VERSION = "0.5"
	
	class IncompatibleTeapot < StandardError
	end
	
	class Loader
		def initialize(context, package)
			@context = context
			@package = package
			
			@defined = []
			@version = nil
		end
		
		attr :package
		attr :defined
		attr :version
		
		def required_version(version)
			if version <= LOADER_VERSION
				@version = version
			else
				raise IncompatibleTeapot.new("Version #{version} more recent than #{LOADER_VERSION}!")
			end
		end

		def define_target(*args, &block)
			target = Target.new(@context, @package, *args)

			yield(target)

			@context.targets[target.name] = target

			@defined << target
		end
		
		def load(path)
			self.instance_eval(File.read(path), path)
		end
	end
	
	class Context
		def initialize(config)
			@config = config

			@selection = nil

			@targets = {config.name => config}

			@dependencies = []
			@selection = Set.new
		end

		attr :config
		attr :targets

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
			
			path = (package.path + package.loader_path).to_s
			loader.load(path)
			
			if loader.version == nil
				raise IncompatibleTeapot.new("No version specified in #{path}!")
			end
			
			loader.defined
		end
	end
end
