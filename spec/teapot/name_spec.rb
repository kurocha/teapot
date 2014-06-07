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

require 'teapot/name'

module Teapot::NameSpec
	describe Teapot::Name do
		let(:name) {Teapot::Name.new('Foo Bar')}
		it "retains the original text" do
			expect(name.text).to be == 'Foo Bar'
		end
		
		it "should generate useful identifiers" do
			expect(name.identifier).to be == 'FooBar'
		end
		
		it "should generate useful target names" do
			expect(name.target).to be == 'foo-bar'
		end
		
		it "should generate useful macro names" do
			expect(name.macro).to be == 'FOO_BAR'
		end
		
		it "should generate useful macro names" do
			expect(name.macro).to be == 'FOO_BAR'
		end
		
		it "can be constructed from target name" do
			expect(Teapot::Name.from_target(name.target).text).to be == name.text
		end
	end
end