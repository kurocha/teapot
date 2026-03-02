# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

module Teapot
	module Command
		AFetch = Sus::Shared("teapot/command/fetch fixture") do
			let(:root) {::Build::Files::Path.new(File.expand_path("fetch", __dir__))}
		end
	end
end
