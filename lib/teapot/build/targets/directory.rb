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

require 'teapot/build/targets/library'
require 'teapot/build/targets/executable'

module Teapot
	module Build
		module Targets
			class Directory < Build::Target
				BUILD_FILE = "build.rb"
				
				def initialize(parent, root)
					@root = root
					@targets = []
				end
		
				attr :root
				attr :tasks
		
				def << (target)
					@targets << target
				end
		
				def add_library(*args, &block)
					@targets << Library.target(self, *args, &block)
				end
		
				def add_executable(*args, &block)
					@targets << Executable.target(self, *args, &block)
				end
		
				def add_directory(path)
					directory = Directory.target(self, @root + path)
			
					build_path = (directory.root + BUILD_FILE).to_s
					directory.instance_eval(File.read(build_path), build_path)
			
					@targets << directory
				end
		
				def execute(command, *arguments)
					@targets.each do |target|
						target.execute(command, *arguments)
					end
				end
			end
		end
	end
end
