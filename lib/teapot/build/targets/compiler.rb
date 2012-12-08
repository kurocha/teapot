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

module Teapot
	module Build
		module Targets
			module Compiler
				def build_prefix!(environment)
					build_prefix = Pathname.new(environment[:build_prefix]) + "compiled"
				
					build_prefix.mkpath
				
					return build_prefix
				end
			
				def link_prefix!(environment)
					prefix = Pathname.new(environment[:build_prefix]) + "linked"
				
					prefix.mkpath
				
					return prefix
				end
				
				def compile(environment, root, source_file, commands)
					object_file = (build_prefix!(environment) + source_file).sub_ext('.o')
				
					# Ensure there is a directory for the output file:
					object_file.dirname.mkpath
				
					case source_file.extname
					when ".cpp", ".mm"
						commands.run(
							environment[:cxx],
							environment[:cxxflags],
							"-c", root + source_file, "-o", object_file
						)
					when ".c", ".m"
						commands.run(
							environment[:cc],
							environment[:cflags],
							"-c", root + source_file, "-o", object_file
						)
					end
			
					return Array object_file
				end
			end
		end
	end
end
