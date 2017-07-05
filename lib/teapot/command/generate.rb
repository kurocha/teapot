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

require 'samovar'
require_relative '../repository'

module Teapot
	module Command
		class Generate < Samovar::Command
			self.description = "Run a generator to create files in your project."
			
			options do
				option '-f/--force', "Force the generator to run even if the current work-tree is dirty."
			end
			
			one :generator_name, "The name of the generator to be invoked."
			many :arguments, "The arguments that will be passed to the generator."
			
			def invoke(parent)
				context = parent.context
				logger = parent.logger
				
				context.configuration.load_all
				
				unless @options[:force]
					# Check dirty status of local repository:
					if Repository.new(context.root).status.size != 0
						abort "You have unstaged changes/unadded files. Please stash/commit them before running the generator.".color(:red)
					end
				end
				
				name, *arguments = @arguments
				generator = context.generators[name]
				
				unless generator
					abort "Could not find generator with name #{name.inspect}".color(:red)
				end
				
				logger.info "Generating #{name.inspect} with arguments #{arguments.inspect}".color(:cyan)
				generator.generate!(*arguments)
			end
		end
	end
end
