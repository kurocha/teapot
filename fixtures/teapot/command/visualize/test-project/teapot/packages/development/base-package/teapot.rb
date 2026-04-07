# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

teapot_version "2.0"

define_project "base-package" do |project|
	project.title = "Base Package"
	project.license = "MIT"
end

define_configuration "development" do |configuration|
end

define_target "base-target" do |target|
	target.provides "Library/Base"
end
