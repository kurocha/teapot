# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'controller'
require_relative 'controller/build'
require_relative 'controller/clean'
require_relative 'controller/create'
require_relative 'controller/fetch'
require_relative 'controller/generate'
require_relative 'controller/list'
require_relative 'controller/visualize'

require_relative 'repository'

require_relative '../flop'

module Teapot
	module Command
		class Create < Flop::Command
			self.description = "Create a new teapot package using the specified repository."
			
			one :project_name, "The name of the new project in title-case, e.g. 'My Project'"
			one :source, "The source repository to use for fetching packages, e.g. https://github.com/kurocha"
			many :packages, "Any additional packages you'd like to include in the project"
			
			def invoke(parent)
				project_path = parent.root || project_name.gsub(/\s+/, '-').downcase
				
				root = Build::Files::Path.expand(@project_path)
				
				if root.exist?
					raise ArgumentError.new("#{root} already exists!")
				end
				
				# Make the path:
				root.create
				
				Teapot::Repository.new(root).init!
				
				parent.controller(root).create(@project_name, @source, @packages)
			end
		end

		class Generate < Flop::Command
			self.description = "Run a generator to create files in your project."
			
			options do
				option '-f | --force', "Force the generator to run even if the current work-tree is dirty.", key: :force
			end
			
			one :generator_name, "The name of the generator to be invoked."
			many :arguments, "The arguments that will be passed to the generator."
			
			def invoke(parent)
				generator_name, *arguments = @arguments
				
				parent.controller.generate(@generator_name, @arguments, @force)
			end
		end

		class Fetch < Flop::Command
			self.description = "Fetch remote packages according to the specified configuration."
			
			options do
				option '--update', "Update dependencies to the latest versions.", key: :update
				option '--no-recursion', "Don't recursively fetch dependencies.", key: :recursion
			end
			
			def invoke(parent)
				# TODO: Need to modify controller to pass arguments through.
				parent.controller.fetch
			end
		end

		class List < Flop::Command
			self.description = "List provisions and dependencies of the specified package."
			
			many :packages, "Limit the listing to only these packages, or all packages if none specified."
			
			def invoke(parent)
				only = nil
				
				if @packages
					only = Set.new(@packages)
				end
				
				parent.controller.list(only)
			end
		end

		class Build < Flop::Command
			self.description = "Build the specified target."
			
			options do
				option '-l <int>', "Limit build the given number of concurrent processes.", key: :limit
				option '--only', "Only compile direct dependencies.", key: :only
				option '--continuous', "Run the build graph continually (experimental).", key: :continuous
			end
			
			many :targets, "Build these targets, or use them to help the dependency resolution process."
			split :argv, "Arguments passed to child process(es) of build if any.", marker: '--'
			
			def invoke(parent)
				# TODO: This is a bit of a hack, figure out a way to pass it directly through to build subsystem.
				ARGV.replace(@argv)
				
				parent.controller.build(@targets)
			end
		end

		class Clean < Flop::Command
			self.description = "Delete everything in the teapot directory."
			
			def invoke(parent)
				parent.controller.clean
			end
		end
		
		class Top < Flop::Command
			self.description = "A decentralised package manager and build tool."
			#version "1.0.0"
			
			options do
				option '-c', "Specify a specific build configuration", key: :configuration
				option '-i <path>', "Work in the given root directory", key: :root
				option '--verbose | --quiet', "Verbose output for debugging.", key: :logging
				option '--help', "Print out help information", key: :help
			end
			
			nested '<command>',
				'create' => Create,
				'generate' => Generate,
				'fetch' => Fetch,
				'list' => List,
				'build' => Build,
				'clean' => Clean
			
			def controller(root = nil, **options)
				Teapot::Controller.new(root || @root || Dir.getwd, **options)
			end
			
			def invoke
				if @command.nil? or @help
					self.class.usage($0)
				else
					@command.invoke(self)
				end
			end
		end
	end
end