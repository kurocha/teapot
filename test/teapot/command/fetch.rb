# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "teapot/command"
require "teapot/command/a_fetch"

describe Teapot::Command::Fetch do
	include_context Teapot::Command::AFetch
	
	let(:project_path) {root + "test-project"}
	let(:thing_path) {root + "repositories/thing"}
	let(:thing_package_path) {project_path + "teapot/packages/test/thing"}
	
	let(:top) {Teapot::Command::Top["--root", project_path.to_s]}
	
	with "clean project" do
		it "should delete all packages" do
			top["clean"].call
			
			expect(File).not.to be(:exist?, root + "test-project/teapot/packages/test")
		end
		
		it "can create thing repository" do
			(thing_path + ".git").delete
			system("git", "init", "-b", "main", chdir: thing_path)
			system("git", "add", "teapot.rb", chdir: thing_path)
			system("git", "commit", "-m", "Teapot file for testing", chdir: thing_path)
		end
		
		it "should delete the lock file" do
			lockfile_path = root + "test-project/test-lock.yml"
			lockfile_path.delete
			
			expect(File).not.to be(:exist?, lockfile_path)
		end
	end
	
	with "initial fetch" do
		let(:subject) {top["fetch"]}
		
		it "should fetch repositories" do
			subject.call
			
			# Did the thing package checkout correctly?
			expect(File).to be(:exist?, root + "test-project/teapot/packages/test/thing/teapot.rb")
		end
		
		it "should fetch repositories with no changes" do
			subject.call
			
			# Did the thing package checkout correctly?
			expect(File).to be(:exist?, root + "test-project/teapot/packages/test/thing/teapot.rb")
		end
	end
	
	with "fetch with worktree modifications" do
		let(:subject) {top["fetch"]}
		let(:path) {root + "test-project/teapot/packages/test/thing/readme.md"}
		
		it "can make local modifications" do
			path.write("Hello World")
			
			expect(File).to be(:exist?, path)
		end
		
		it "can't fetch with local modifications" do
			expect{subject.call}.to raise_exception(Teapot::Command::FetchError, message: be =~ /local modifications/)
			
			path.delete
		end
	end
	
	with "fetch with upstream changes" do
		let(:subject) {top["fetch", "--update"]}
		
		it "can commit upstream changes" do
			system("git", "add", "readme.md", chdir: thing_path)
			system("git", "commit", "-m", "Add documentation", chdir: thing_path)
		end
		
		it "can fetch changes" do
			subject.call
			
			expect(File).to be(:exist?, thing_package_path + "readme.md")
		end
	end
end
