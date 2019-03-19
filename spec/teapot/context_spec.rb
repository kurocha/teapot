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

RSpec.describe Teapot::Context do
	let(:root) {Build::Files::Path.new(__dir__) + "context_spec"}
	let(:context) {Teapot::Context.new(root)}
	
	it "should specify correct number of packages" do
		default_configuration = context.configuration
		
		expect(default_configuration.packages.count).to be == 0
	end
	
	it "should select configuration" do
		expect(context.configuration.name).to be == 'development'
	end
	
	context "with specific configuration" do
		let(:context) {Teapot::Context.new(root, configuration: 'context_spec')}
		
		it "should select configuration" do
			expect(context.configuration.name).to be == 'context_spec'
		end
		
		it "should specify correct number of packages" do
			default_configuration = context.configuration
			
			expect(default_configuration.packages.count).to be == 13
		end
	end
	
	it "should load teapot script" do
		selection = context.select
		
		# There is one configuration:
		expect(selection.configurations.count).to be == 2
		expect(selection.targets.count).to be == 1
		
		# We didn't expect any of them to actually load...
		expect(selection.unresolved.count).to be > 0
	end
end
