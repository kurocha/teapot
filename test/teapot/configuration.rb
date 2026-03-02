# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "teapot/context"
require "teapot/configuration"
require "teapot/a_configuration"

describe Teapot::Configuration do
	include_context Teapot::AConfiguration
	
	let(:context) {Teapot::Context.new(root)}
	
	it "merged targets" do
		selection = context.select
		
		expect(selection.configuration.targets[:build]).to be == ["Bar", "Foo"]
	end
end
