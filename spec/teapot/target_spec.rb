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

require 'teapot/context'
require 'pry'

module Teapot::TargetSpec
	ROOT = Build::Files::Path.new(__dir__) + "target_spec"
	
	describe Teapot::Target do
		it "should generate environment for configuration" do
			context = Teapot::Context.new(ROOT)
			
			target = context.targets['target_spec_with_dependencies']
			expect(target).to_not be nil
			
			chain = context.dependency_chain(["Test/TargetSpecWithDependencies"])
			expect(chain.providers).to include target
			
			ordered = chain.ordered
			expect(ordered.size).to be == 2
			
			binding.pry
			
			ordered.each do |(target, dependency)|
				environment = target.environment_for_configuration(context.configuration)
			end
		end
	end
end
