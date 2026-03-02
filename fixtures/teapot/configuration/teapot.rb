# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

teapot_version "2.0"

define_configuration "build-bar" do |configuration|
	configuration.import "build-foo"
	
	configuration.targets[:build] << "Bar"
end

define_configuration "build-foo" do |configuration|
	configuration.targets[:build] << "Foo"
end

