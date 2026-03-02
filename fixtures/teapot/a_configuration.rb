# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require "sus/shared"
require "build/files"

module Teapot
	AConfiguration = Sus::Shared("teapot/configuration fixture") do
		let(:root) {::Build::Files::Path.new(File.expand_path("configuration", __dir__))}
	end
end
