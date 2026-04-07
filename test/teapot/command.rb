# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "teapot/command"
require "sus/fixtures/temporary_directory_context"

describe Teapot::Command do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	let(:source) {"https://github.com/kurocha"}
	let(:project_name) {"Test Project"}
	let(:project_path) {File.join(root, "test-project")}
	
	let(:top) {Teapot::Command::Top["--root", project_path.to_s]}
	
	it "can create and build a project" do
		top["create", project_name, source.to_s, "generate-project"].call
		top["build", "Run/TestProject"].call
	end
end
