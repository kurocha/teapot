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
require 'teapot/configuration'

RSpec.describe Teapot::Configuration do
	let(:root) {Build::Files::Path[__dir__] + 'configuration_spec'}
	
	let(:context) {Teapot::Context.new(root, load_root: false)}
	let(:master) {Teapot::Configuration.new(context, Teapot::Package.new(root + 'master', 'master'), 'master')}
	let(:embedded) {Teapot::Configuration.new(context, Teapot::Package.new(root + 'embedded', 'embedded'), 'embedded')}
	
	context "with create targets" do
		before(:each) do
			master.targets[:create] << "hello"
			embedded.targets[:create] << "world"
		end
		
		it "can merge packages" do
			expect(master.update(embedded, {})).to be_truthy
			
			expect(master.targets[:create]).to be == ["hello", "world"]
		end
	end
end
