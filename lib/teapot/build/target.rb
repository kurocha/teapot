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

require 'teapot/commands'
require 'teapot/environment'

require 'pathname'
require 'fileutils'

require 'teapot/build/linker'
require 'teapot/build/component'

module Teapot
	module Build
		class Target
			def initialize(parent)
				@parent = parent
				@configure = nil
			end
		
			attr :parent
		
			def root
				@parent.root
			end
		
			def configure(&block)
				@configure = Proc.new &block
			end
		
			def self.target(*args, &block)
				instance = self.new(*args)
			
				if block_given?
					instance.instance_eval(&block)
				end
			
				return instance
			end

			def execute(command, environment, *arguments)
				if @configure
					environment = environment.merge &@configure
				end

				# Flatten the environment to a hash:
				flat_environment = environment.flatten

				puts "Performing #{self.class}/#{command} for #{root}...".color(:cyan)

				# Show the environment to the user:
				Environment::System::dump(flat_environment)

				self.send(command, flat_environment, *arguments)
			end
		end
	end
end
