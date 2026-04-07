# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "teapot/command"
require "teapot/a_command"

describe Teapot::Command do
	include_context Teapot::ACommand
	
	let(:source) {"https://github.com/kurocha"}
	# let(:source) {File.expand_path("../../../../kurocha", __dir__)}
	let(:project_name) {"Test Project"}
	let(:project_path) {root + "test-project"}
	
	let(:top) {Teapot::Command::Top["--root", project_path.to_s]}
	
	with "Teapot::Command::Create" do
		let(:subject) {top["create", project_name, source.to_s, "generate-project"]}
		
		it "should create a new project" do
			root.delete
			
			subject.call
			expect(project_path + "teapot.rb").to be(:exist?)
		end
	end
	
	with "Teapot::Command::Build" do
		let(:subject) {top["build", "Run/TestProject"]}
		
		it "should build project" do
			subject.call
		end
	end
	
	with "Teapot::Command::Fetch" do
		let(:subject) {top["fetch"]}
		
		it "should fetch any changes" do
			subject.call
		end
	end
end
