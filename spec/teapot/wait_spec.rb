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

require 'teapot/context'
require 'build/controller'

module Teapot::WaitSpec
	ROOT = Build::Files::Path.join(__dir__, "wait_spec")
		
	describe Teapot::Target do
		let(:logger) {Logger.new($stdout).tap{|logger| logger.level = Logger::DEBUG; logger.formatter = Build::CompactFormatter.new}}
		
		it "should wait on completion of dependent targets" do
			context = Teapot::Context.new(ROOT)
			
			a, b, c = context.targets.values_at('A', 'B', 'C')
			
			chain = context.dependency_chain(["Teapot/C"])
			ordered = chain.ordered
			
			controller = Build::Controller.new(logger: logger) do |controller|
				ordered.each do |resolution|
					target = resolution.provider
					
					environment = target.environment(context.configuration)
					
					if target.build
						controller.add_target(target, environment.flatten)
					end
				end
			end
			
			controller.update
			
			puts $log
		end
	end
end
