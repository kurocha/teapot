# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

module Teapot
	AContext = Sus::Shared("teapot/context fixture") do
		let(:root) {::Build::Files::Path.new(File.expand_path("context", __dir__))}
	end
end
