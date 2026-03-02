# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2026, by Samuel Williams.

require "teapot/context"
require "teapot/a_context"

describe Teapot::Context do
	include_context Teapot::AContext
	
	let(:context) {Teapot::Context.new(root)}
	
	it "should specify correct number of packages" do
		default_configuration = context.configuration
		
		expect(default_configuration.packages.count).to be == 0
	end
	
	it "should select configuration" do
		expect(context.configuration.name).to be == "development"
	end
	
	with "specific configuration" do
		let(:context) {Teapot::Context.new(root, configuration: "context_spec")}
		
		it "should select configuration" do
			expect(context.configuration.name).to be == "context_spec"
		end
		
		it "should specify correct number of packages" do
			default_configuration = context.configuration
			
			expect(default_configuration.packages.count).to be == 13
		end
	end
	
	it "should load teapot script" do
		selection = context.select
		
		# There is one configuration:
		expect(selection.configurations.count).to be == 2
		expect(selection.targets.count).to be == 1
		
		# We didn't expect any of them to actually load...
		expect(selection.unresolved.count).to be > 0
	end
end
