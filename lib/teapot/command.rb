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
	class Command
		def initialize(arguments, options)
			@action, *@arguments = arguments
			@options = options
		end
		
		def controller(root = nil)
			Teapot::Controller.new(root || @options[:in], @options)
		end
		
		def invoke
			if @action == "invoke"
				fail "The meaning of life is 42."
			end
			
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
		
		alias brew build
		
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