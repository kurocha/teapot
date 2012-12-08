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

require 'teapot/build/target'
require 'teapot/build/targets/directory'
require 'teapot/build/targets/compiler'

require 'fileutils'

module Teapot
	module Build
		module Targets
			module Installation
				def install_prefix!(environment)
					install_prefix = Pathname.new(environment[:install_prefix])
				
					install_prefix.mkpath
				
					return install_prefix
				end
			end
			
			class Files < Build::Target
				include Installation
				
				def initialize(parent, options = {})
					super parent
					@options = options
				end
				
				attr :options
				
				def subdirectory
					options[:subdirectory] || "./"
				end
				
				def install(environment)
					prefix = install_prefix!(environment)
					
					if self.respond_to? :source_files
						file_list = self.source_files(environment)
						
						file_list.copy(prefix + subdirectory)
					end
				end
			end
			
			class Headers < Files
				def subdirectory
					super + "include/"
				end
			end
			
			class Directory
				def copy_files(*args, &block)
					self << Files.target(self, *args, &block)
				end
				
				def copy_headers(*args, &block)
					self << Headers.target(self, *args, &block)
				end
			end
		end
	end
end
