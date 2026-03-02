# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

module Teapot
	# Scratch directory used by create/build/fetch command integration tests.
	# The test deletes and recreates this directory during the run.
	ACommand = Sus::Shared("teapot/command fixture") do
		let(:root) {::Build::Files::Path.new(File.expand_path("run", __dir__))}
	end
end
