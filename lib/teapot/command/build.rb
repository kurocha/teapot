# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'build/controller'

module Teapot
	module Command
		class BuildFailedError < StandardError
		end
		
		class Build < Samovar::Command
			self.description = "Build the specified target."
			
			options do
				option '-j/-l/--limit <n>', "Limit the build to <n> concurrent processes.", type: Integer
				option '-c/--continuous', "Run the build graph continually (experimental)."
			end
			
			many :targets, "Build these targets, or use them to help the dependency resolution process."
			split :argv, "Arguments passed to child process(es) of build if any."
			
			def invoke(parent)
				context = parent.context
				
				# The targets to build:
				if @targets.any?
					selection = context.select(@targets)
				else
					selection = context.select(context.configuration.targets[:build])
				end
				
				chain = selection.chain
				environment = context.configuration.environment
				
				controller = ::Build::Controller.new(logger: parent.logger, limit: @options[:limit]) do |controller|
					
					controller.add_chain(chain, self.argv, environment)
				end
				
				walker = nil
				
				# We need to catch interrupt here, and exit with the correct exit code:
				begin
					controller.run do |walker|
						# show_dependencies(walker)
						
						# Only run once is asked:
						unless @options[:continuous]
							if walker.failed?
								raise BuildFailedError.new("Failed to build all nodes successfully!")
							end
						
							break
						end
					end
				rescue Interrupt
					if walker && walker.failed?
						raise BuildFailedError.new("Failed to build all nodes successfully!")
					end
				end
				
				return chain
			end
			
			def show_dependencies(walker)
				outputs = {}
				
				walker.tasks.each do |node, task|
					# puts "Task #{task} (#{node}) outputs:"
					
					task.outputs.each do |path|
						path = path.to_s
						
						# puts "\t#{path}"
						
						outputs[path] = task
					end
				end
				
				walker.tasks.each do |node, task|
					dependencies = {}
					task.inputs.each do |path|
						path = path.to_s
						
						if generating_task = outputs[path]
							dependencies[path] = generating_task
						end
					end
					
					puts "Task #{task.inspect} has #{dependencies.count} dependencies."
					dependencies.each do |path, task|
						puts "\t#{task.inspect}: #{path}"
					end
				end
			end
		end
	end
end
