# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

require "sus/fixtures/temporary_directory_context"

module Teapot
	module Command
		# Scratch directory used by clone integration tests.
		# The test deletes and recreates this directory during the run.
		AClone = Sus::Shared("a clone") do
			include Sus::Fixtures::TemporaryDirectoryContext
			
			let(:clone_root) {::Build::Files::Path.new(File.expand_path("clone", root))}
		end
	end
end
