
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

required_version "0.7"

define_configuration 'test' do |config|
	config[:source] = "../dream-framework"

	config.package "variants"

	config.package "platform-darwin-osx"
	config.package "platform-darwin-ios"

	config.package "unit-test"
	config.package "euclid"

	config.package "ogg"
	config.package "vorbis"

	config.package "jpeg"
	config.package "png"

	config.package "freetype"

	config.package "dream"
	config.package "tagged-format"

	config.package "opencv"
end
