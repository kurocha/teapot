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

require 'teapot/controller'
require 'build/controller'

$TEAPOT_DEBUG_GRAPH = false

module Teapot
	class Controller
		class BuildFailedError < StandardError
		end
		
		def build(dependency_names)
			chain = context.dependency_chain(dependency_names, context.configuration)
		
			ordered = chain.ordered
		
			if @options[:only]
				ordered = context.direct_targets(ordered)
			end
			
			controller = Build::Controller.new(logger: self.logger) do |controller|
				ordered.each do |(target, dependency)|
					environment = target.environment(context.configuration)
					
					if target.build
						controller.add_target(target, environment.flatten)
					end
				end
			end
			
			walker = nil
			
			# We need to catch interrupt here, and exit with the correct exit code:
			begin
				controller.run do |walker|
					if $TEAPOT_DEBUG_GRAPH
						controller.nodes.each do |key, node|
							puts "#{node.status} #{node.inspect}" unless node.clean?
						end
					end
					
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
