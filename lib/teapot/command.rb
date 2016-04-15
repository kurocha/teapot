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

require 'trollop'

module Teapot
	# This module implements all top-level teapot commands.
	module Command
		def self.parse(arguments)
			options = Trollop::options(arguments) do
				banner Rainbow("Teapot: a decentralised package manager and build tool.").bright.blue
				version "teapot v#{Teapot::VERSION}"
				
				opt :configuration, "Specify a specific build configuration.", :type => :string
				
				opt :limit, "Limit build to <i> concurrent processes at once where possible", :type => :integer
				
				opt :only, "Only compiled direct dependencies."
				opt :continuous, "Run the build graph continually (experimental).", :type => :boolean, :short => :n
				
				opt :in, "Work in the given directory.", :type => :string, :default => Dir.getwd
				opt :unlock, "Don't use package lockfile when fetching."
				
				opt :force, "Force the operation if it would otherwise be be stopped due to a warning."
				
				opt :verbose, "Verbose output and error backtraces.", :type => :boolean
				opt :version, "Print version and exit", :short => :none
				
				opt :help, "Show this message"
			end
			
			action = arguments.shift
			
			self.new(action, options, arguments)
		end
		
		def initialize(action, options, arguments)
			@action = action
			@options = options
			@arguments = arguments
		end
		
		def controller(root = nil)
			Teapot::Controller.new(root || @options[:in], @options)
		end
		
		def invoke
			self.send(@action)
		end
		
		def clean
			controller.clean
		end
		
		def fetch
			controller.fetch
		end
		
		def list
			only = nil
			
			if @arguments.any?
				only = Set.new(@arguments)
			end
			
			controller.list(only)
		end
		
		def generate
			generator_name, *arguments = @arguments
			
			controller.generate(generator_name, arguments, @options[:force])
		end
		
		def build
			controller.build(@arguments)
		end
		
		def visualize
			controller.visualize(@arguments)
		end
		
		def create
			project_name, source, *packages = @arguments
			project_path = @options.fetch(:in) {project_name.gsub(/\s+/, '-').downcase}
			
			root = Build::Files::Path.join(Dir.getwd, project_path)
			
			if root.exist?
				abort "#{root} already exists!".color(:red)
			end
			
			# Make the path:
			root.create
			
			Teapot::Repository.new(root).init!
			
			controller(root).create(project_name, source, packages)
		end
	end
end