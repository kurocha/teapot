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
require 'rainbow'
require 'shellwords'

require 'teapot/build/linker'
require 'teapot/build/component'
require 'teapot/build/file_list'

module Teapot
	module Build
		class UnsupportedPlatform < StandardError
		end
		
		class Task
			def initialize(inputs, outputs)
				@inputs = inputs
				@outputs = outputs
			end
		end
	
		class Target
			def initialize(parent)
				@parent = parent
				@tasks = []
				
				@configure = nil
			end
		
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
				values = environment.flatten
			
				puts "Executing command #{command} for #{root}...".color(:cyan)
			
				# Show the environment to the user:
				Environment::System::dump(values)
				
				self.send(command, values, *arguments)
			end
		end
	
		class CompilerTarget < Target
			def initialize(parent, name, options = {})
				super parent
			
				@name = name
				@options = options
			end
			
			def build_prefix!(environment)
				build_prefix = Pathname.new(environment[:build_prefix]) + "compiled"
				
				build_prefix.mkpath
				
				return build_prefix
			end
			
			def link_prefix!(environment)
				prefix = Pathname.new(environment[:build_prefix]) + "products"
				
				prefix.mkpath
				
				return prefix
			end
			
			def install_prefix!(environment)
				install_prefix = Pathname.new(environment[:install_prefix])
				
				install_prefix.mkpath
				
				return install_prefix
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
	
		class Library < CompilerTarget
			def subdirectory
				"lib"
			end
			
			def link(environment, objects)
				library_file = link_prefix!(environment) + "lib#{@name}.a"
				
				Linker.link_static(environment, library_file, objects)
				
				return library_file
			end
			
			def build(environment)
				file_list = self.sources(environment)
				
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
					destination_path = prefix + relative_path
					
					destination_path.dirname.mkpath
					FileUtils.cp path, destination_path
				end
			end
			
			def install(environment)
				prefix = install_prefix!(environment)
				
				build(environment).each do |path|
					destination_path = prefix + subdirectory + path.basename
					
					destination_path.dirname.mkpath
					
					FileUtils.cp path, destination_path
				end
				
				if self.respond_to? :headers
					install_file_list(self.headers(environment), prefix + "include")
				end
				
				if self.respond_to? :files
					install_file_list(self.files(environment), prefix)
				end
			end
		end
	
		class Executable < Library
			def subdirectory
				"bin"
			end
			
			def link(environment, objects)
				executable_file = link_prefix!(environment) + @name
			
				Commands.run(
					environment[:cxx],
					environment[:cxxflags],
					"-o", executable_file, objects,
					environment[:ldflags]
				)
			
				return executable_file
			end
		end
	
		class Directory < Target
			def initialize(parent, root)
				@root = root
				@targets = []
			end
		
			attr :root
			attr :tasks
		
			def add_library(*args, &block)
				@targets << Library.target(self, *args, &block)
			end
		
			def add_executable(*args, &block)
				@targets << Executable.target(self, *args, &block)
			end
		
			def add_directory(path)
				directory = Directory.target(self, @root + path)
			
				build_path = (directory.root + "build.rb").to_s
				directory.instance_eval(File.read(build_path), build_path)
			
				@targets << directory
			end
		
			def execute(command, *arguments)
				$stderr.puts "Executing #{command} for #{@root}"
				@targets.each do |target|
					target.execute(command, *arguments)
				end
			end
		end
	
		def self.top(path)
			Directory.target(nil, path)
		end
	end
end
