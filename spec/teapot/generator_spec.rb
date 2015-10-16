# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
require 'build/files/system'

module Teapot::GeneratorSpec
	ROOT = Build::Files::Path.new(__dir__)
	TMP_PATH = ROOT + 'tmp'
	ALICE_PATH = TMP_PATH + 'Alice.txt'
	
	describe Teapot::Generator do
		after do
			TMP_PATH.delete
		end
		
		it "should rename files and expand variables" do
			context = Teapot::Context.new(ROOT)
		
			generator = context.generators["generator_spec"]
			
			generator.generate!
			
			expect(TMP_PATH).to be_exist
			expect(ALICE_PATH).to be_exist
			expect(ALICE_PATH.read).to be =~ /42/
		end
	end
end
