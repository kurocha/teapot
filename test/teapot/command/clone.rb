# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "teapot/command"
require "teapot/command/a_clone"

describe Teapot::Command::Clone do
	include Teapot::Command::AClone
	
	let(:source) {"https://github.com/kurocha/tagged-format"}
	
	let(:top) {Teapot::Command::Top["--root", clone_root.to_s]}
	
	with "clone remote source" do
		let(:subject) {top["clone", source]}
		
		it "should checkout files" do
			subject.call
			
			expect(File).to be(:exist?, File.join(clone_root, "teapot.rb"))
			
			selection = top.context.select
			
			# Check that we actually fetched some remote targets.
			expect(selection.targets).to have_keys(
				"tagged-format-library",
				"tagged-format-executable",
				"build-files",
				"unit-test-library",
				"variant-debug",
				"variant-release",
			)
		end
	end
end
