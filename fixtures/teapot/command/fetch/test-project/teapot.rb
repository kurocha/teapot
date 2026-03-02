# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

teapot_version "2.0"

define_configuration "test" do |configuration|
	configuration[:source] = "../repositories"
	
	configuration.require "thing"
end
