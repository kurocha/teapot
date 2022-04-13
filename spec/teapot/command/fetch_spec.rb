
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

RSpec.xdescribe Teapot::Command::Fetch, order: :defined do
	let(:root) {Build::Files::Path.new(__dir__) + "fetch_spec"}
	let(:project_path) {root + 'test-project'}
	let(:thing_path) {root + "repositories/thing"}
	let(:thing_package_path) {project_path + "teapot/packages/test/thing"}
	
	let(:top) {Teapot::Command::Top["--root", project_path.to_s]}
	
	context "clean project" do
		subject {top['clean']}
		
		it "should delete all packages" do
			expect{subject.call}.to_not raise_error
			
			expect(File).to_not be_exist(root + "test-project/teapot/packages/test")
		end
		
		it "can create thing repository" do
			(thing_path + ".git").delete
			
			system("git", "init", chdir: thing_path)
			system("git", "add", "teapot.rb", chdir: thing_path)
			system("git", "commit", "-m", "Teapot file for testing", chdir: thing_path)
		end
		
		let(:lockfile_path) {root + "test-project/test-lock.yml"}
		
		it "should delete the lock file" do
			lockfile_path.delete
			
			expect(File).to_not be_exist(lockfile_path)
		end
	end
	
	context "initial fetch" do
		subject {top['fetch']}
		
		it "should fetch repositories" do
			expect{subject.call}.to_not raise_error
			
			# Did the thing package checkout correctly?
			expect(File).to be_exist(root + "test-project/teapot/packages/test/thing/teapot.rb")
		end
		
		it "should fetch repositories with no changes" do
			expect{subject.call}.to_not raise_error
			
			# Did the thing package checkout correctly?
			expect(File).to be_exist(root + "test-project/teapot/packages/test/thing/teapot.rb")
		end
	end
	
	context "fetch with worktree modifications" do
		subject {top['fetch']}
		let(:path) {root + "test-project/teapot/packages/test/thing/README.md"}
		
		it "can make local modifications" do
			path.write("Hello World")
			
			expect(File).to be_exist(path)
		end
		
		it "can't fetch with local modifications" do
			expect{subject.call}.to raise_error(Teapot::Command::FetchError, /local modifications/)
			
			path.delete
		end
	end
	
	context "fetch with upstream changes" do
		subject {top['fetch', '--update']}
		
		it "can commit upstream changes" do
			system("git", "add", "README.md", chdir: thing_path)
			system("git", "commit", "-m", "Add documentation", chdir: thing_path)
		end
		
		it "can fetch changes" do
			expect{subject.call}.to_not raise_error
			
			expect(File).to be_exist(thing_package_path + "README.md")
		end
	end
end
