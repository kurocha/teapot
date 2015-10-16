
#
#  This file is part of the "Teapot" project, and is released under the MIT license.
#

teapot_version "1.0.0"

define_configuration 'test' do |configuration|
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

define_generator "generator_spec" do |generator|
	generator.generate do
		directory = Files::Path.new('tmp')
		
		directory.mkpath
		
		substitutions = Substitutions.new
		
		substitutions['NAME'] = 'Alice'
		substitutions['VARIABLE'] = '42'
		
		generator.copy('generator_spec', directory, substitutions)
	end
end