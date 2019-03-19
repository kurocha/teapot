
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "3.0.0"

define_target "context_spec" do |target|
end

define_configuration 'development' do |configuration|
	configuration.import 'context_spec'
end

define_configuration 'context_spec' do |configuration|
	configuration.public!
	
	configuration[:source] = "../kurocha"

	configuration.require "variants"

	configuration.require "platform-darwin-osx"
	configuration.require "platform-darwin-ios"

	configuration.require "unit-test"
	configuration.require "euclid"

	configuration.require "ogg"
	configuration.require "vorbis"

	configuration.require "jpeg"
	configuration.require "png"

	configuration.require "freetype"

	configuration.require "dream"
	configuration.require "tagged-format"

	configuration.require "opencv"
end
