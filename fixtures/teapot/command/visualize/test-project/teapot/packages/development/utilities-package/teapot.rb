# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

teapot_version "2.0"

define_project "utilities-package" do |project|
	project.title = "Utilities Package"
	project.license = "MIT"
end

define_configuration "development" do |configuration|
	configuration.require "base-package"
end

define_target "utilities-target" do |target|
	target.provides "Library/Utilities"
end
