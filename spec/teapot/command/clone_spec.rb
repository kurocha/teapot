
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

require 'teapot/command'

RSpec.describe Teapot::Command::Clone, order: :defined do
	let(:root) {Build::Files::Path.new(__dir__) + "clone_spec"}
	let(:source) {'https://github.com/kurocha/tagged-format'}
	
	let(:top) {Teapot::Command::Top["--root", root.to_s]}
	
	before do
		root.delete
	end
	
	context "clone remote source" do
		subject {top['clone', source]}
		
		it "should checkout files" do
			expect{subject.call}.to_not raise_error
			
			expect(File).to be_exist(root + "teapot.rb")
			
			selection = top.context.select
			
			# Check that we actually fetched some remote targets.
			expect(selection.targets).to include(
				"tagged-format-library",
				"tagged-format-executable",
				"tagged-format-tests",
				"build-files",
				"unit-test-library",
				"unit-test-tests",
				"variant-debug",
				"variant-release",
			)
		end
	end
end
