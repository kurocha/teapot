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

module Teapot::CommandSpec
	ROOT = Build::Files::Path.new(__dir__) + "command_spec"
	PROJECT_PATH = ROOT + 'test-project'
	
	describe Teapot::Command::Top.parse(["--in", PROJECT_PATH.to_s, "create", "test-project", "https://github.com/kurocha", "project"]) do
		before do
			ROOT.mkpath
		end
		
		after do
			PROJECT_PATH.delete
		end
		
		it "should create a new project" do
			expect{subject.invoke}.to_not raise_error
			expect(PROJECT_PATH + "teapot.rb").to be_exist
		end
	end
end
