
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "1.0.0"

define_configuration 'test' do |configuration|
	configuration.public!
	
	configuration[:source] = "../dream-framework"

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
