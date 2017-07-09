
teapot_version "2.0"

define_configuration "test" do |configuration|
	configuration[:source] = "../repositories"
	
	configuration.require "thing"
end
