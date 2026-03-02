# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

module Teapot
	ATarget = Sus::Shared("teapot/target fixture") do
		let(:root) {::Build::Files::Path.new(File.expand_path("target", __dir__))}
	end
end
