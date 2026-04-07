# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

require "sus/fixtures/temporary_directory_context"

module Teapot
	module Command
		VisualizeContext = Sus::Shared("a visualize") do
			include Sus::Fixtures::TemporaryDirectoryContext
			
			let(:project_path) {::Build::Files::Path.new(File.expand_path("visualize/test-project", __dir__))}
		end
	end
end
