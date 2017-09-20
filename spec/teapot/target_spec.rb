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

RSpec.describe Teapot::Target do
	let(:root) {Build::Files::Path.new(__dir__) + "target_spec"}
	
	it "should generate environment for configuration" do
		context = Teapot::Context.new(root)
		selection = context.select(["Test/TargetSpec"])
		
		target = selection.targets['target_spec']
		expect(target).to_not be == nil
		
		chain = selection.chain
		expect(chain.providers.size).to be == 4
		expect(chain.providers).to include target
		
		expect(chain.ordered.size).to be == 3
		expect(chain.ordered[0].name).to be == 'Variant/debug'
		expect(chain.ordered[1].name).to be == 'Platform/generic'
		expect(chain.ordered[2].name).to be == 'Test/TargetSpec'
		expect(chain.ordered[2].provider).to be == target
		
		environment = target.environment(selection.configuration, chain)
		# Environment#to_hash flattens the environment and evaluates all values:
		hash = environment.to_hash
		
		expect(hash[:variant]).to be == 'debug'
		expect(hash[:platform_name]).to be == 'generic'
		
		expect(hash).to include(:buildflags, :linkflags, :build_prefix, :install_prefix, :platforms_path)
	end
	
	it "should match wildcard packages" do
		context = Teapot::Context.new(root)
		selection = context.select(["Test/*"])
		
		target = selection.targets['target_spec']
		expect(target).to_not be == nil
		
		chain = selection.chain
		expect(chain.providers.size).to be == 4
		expect(chain.providers).to include target
	end
end
