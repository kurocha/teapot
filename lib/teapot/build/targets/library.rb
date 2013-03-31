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
require 'teapot/build/targets/files'
require 'teapot/build/targets/compiler'

require 'teapot/build/graph'

require 'fileutils'

module Teapot
	module Build
		module Targets
			class Library < Build::Target
				include Compiler
				include Installation

				def initialize(parent, name, options = {})
					super parent
			
					@name = name
					@options = options
				end
				
				attr :options
				
				def subdirectory
					options[:subdirectory] || "lib"
				end
				
				def link(environment, objects)
					library_file = link_prefix!(environment) + "lib#{@name}.a"
				
					graph = Build::dependency_graph(environment)
					
					if graph.regenerate?(library_file, objects)
						Linker.link_static(environment, library_file, objects)
					end
					
					return library_file
				end
			
				def compile_and_link(environment)
					file_list = self.source_files(environment)
				
					pool = Commands::Pool.new
				
					objects = file_list.collect do |source_file|
						relative_path = source_file.relative_path_from(file_list.root)
					
						compile(environment, file_list.root, relative_path, pool)
					end
				
					pool.wait
				
					return Array link(environment, objects)
				end
			
				def install_file_list(file_list, prefix)
					file_list.each do |path|
						relative_path = path.relative_path_from(file_list.root)
						destination_path = prefix + file_list.prefix + relative_path
					
						destination_path.dirname.mkpath
						FileUtils.cp(path, destination_path, :preserve => true)
					end
				end
			
				def build(environment)
					prefix = install_prefix!(environment)
					
					compile_and_link(environment).each do |path|
						destination_path = prefix + subdirectory + path.basename
					
						destination_path.dirname.mkpath
					
						FileUtils.cp(path, destination_path, :preserve => true)
					end
					
					if self.respond_to? :headers
						install_file_list(self.headers(environment), prefix + "include")
					end
				end
			end
			
			class Directory
				def compile_library(*args, &block)
					self << Library.target(self, *args, &block)
				end
			end
		end
	end
end
