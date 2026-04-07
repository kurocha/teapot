# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

teapot_version "2.0"

define_project "test-project" do |project|
	project.title = "Test Project"
	project.license = "MIT"
end

define_configuration "development" do |configuration|
	configuration.targets[:build] << "test-target"
end

define_target "test-target" do |target|
	target.depends "library"
	target.depends "utilities"
end

define_target "library" do |target|
	target.depends "base"
end

define_target "utilities" do |target|
end

define_target "base" do |target|
end
