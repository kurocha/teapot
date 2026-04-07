# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "sus/shared"
require "build/files"

require "sus/fixtures/temporary_directory_context"

module Teapot
	module Command
		AFetch = Sus::Shared("a fetch") do
			include Sus::Fixtures::TemporaryDirectoryContext
			
			let(:fetch_root) {::Build::Files::Path.new(File.expand_path("fetch", __dir__))}
			
			before do
				FileUtils.cp_r(File.join(fetch_root, "test-project"), root)
			end
		end
	end
end
