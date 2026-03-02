# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

module Teapot
	module Command
		# Scratch directory used by clone integration tests.
		# The test deletes and recreates this directory during the run.
		AClone = Sus::Shared("teapot/command/clone fixture") do
			let(:root) {::Build::Files::Path.new(File.expand_path("clone", __dir__))}
		end
	end
end
