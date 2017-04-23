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

require_relative '../controller'
require 'build/controller'

module Teapot
	class Controller
		class BuildFailedError < StandardError
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
		
		def build(dependency_names)
			chain = context.dependency_chain(dependency_names, context.configuration)
			
			ordered = chain.ordered
			
			if @options[:only]
				ordered = context.direct_targets(ordered)
			end
			
			controller = Build::Controller.new(logger: self.logger, limit: @options[:limit]) do |controller|
				ordered.each do |resolution|
					target = resolution.provider
					
					environment = target.environment(context.configuration, chain)
					
					if target.build
						controller.add_target(target, environment.flatten)
					end
				end
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
			
			return chain, ordered
		end
	end
end
