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
require 'teapot/build'

module Teapot
	class Controller
		def build(dependency_names)
			chain = context.dependency_chain(dependency_names, context.configuration)
		
			ordered = chain.ordered
		
			if @options[:only]
				ordered = context.direct_targets(ordered)
			end
			
			controller = Teapot::Build::Controller.new do |controller|
				ordered.each do |(target, dependency)|
					environment = target.environment_for_configuration(context.configuration)
					
					if target.build
						controller.add_target(target, environment.flatten)
					end
				end
			end
			
			controller.run do
				# The graph has been dirtied because files have changed, traverse and update it:
				controller.update_with_log
				
				# Only run once is asked:
				if @options[:once]
					break
				end
				
				if $TEAPOT_DEBUG_GRAPH
					controller.nodes.each do |key, node|
						puts "#{node.status} #{node.inspect}"# unless node.clean?
					end
				end
			end
			
			return chain, ordered
		end
	end
end
