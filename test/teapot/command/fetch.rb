# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "teapot/command"
require "teapot/command/a_fetch"

describe Teapot::Command::Fetch do
	include Teapot::Command::AFetch
	
	let(:project_path) {File.join(root, "test-project")}
	let(:thing_path) {File.join(root, "repositories/thing")}
	let(:thing_package_path) {File.join(project_path, "teapot/packages/test/thing")}
	
	let(:top) {Teapot::Command::Top["--root", project_path.to_s]}
	
	with "clean project" do
		it "should delete all packages" do
			top["clean"].call
			
			expect(File).not.to be(:exist?, File.join(root, "test-project/teapot/packages/test"))
		end
		
		it "can create thing repository" do
			system("git", "init", "-b", "main", chdir: thing_path)
			system("git", "add", "teapot.rb", chdir: thing_path)
			system("git", "commit", "-m", "Teapot file for testing", chdir: thing_path)
		end
	end
	
	with "fetch" do
		let(:subject) {top["fetch"]}
		
		it "should fetch repositories" do
			subject.call
			
			# Did the thing package checkout correctly?
			expect(File).to be(:exist?, File.join(root, "test-project/teapot/packages/test/thing/teapot.rb"))
		end
		
		let(:local_path) {File.join(root, "test-project/teapot/packages/test/thing/readme.md")}
		
		it "can't fetch with local modifications" do
			subject.call
			
			File.write(local_path, "Hello World")
			
			expect{subject.call}.to raise_exception(Teapot::Command::FetchError, message: be =~ /local modifications/)
		end
	end
end
