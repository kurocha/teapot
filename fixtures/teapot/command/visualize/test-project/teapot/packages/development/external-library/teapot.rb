# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

teapot_version "2.0"

define_project "external-library" do |project|
	project.title = "External Library"
	project.license = "MIT"
end

define_configuration "development" do |configuration|
	configuration.require "base-package"
end

define_target "external-library-target" do |target|
	target.provides "Library/External"
end
