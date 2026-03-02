# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require "teapot/context"
require "teapot/a_target"

describe Teapot::Target do
	include_context Teapot::ATarget
	
	it "should generate correct chain for configuration" do
		context = Teapot::Context.new(root)
		selection = context.select(["Test/TargetSpec"])
		
		target = selection.targets["target_spec"]
		expect(target).not.to be_nil
		
		chain = selection.chain
		expect(chain.providers.size).to be == 4
		expect(chain.providers).to be(:include?, target)
		
		expect(chain.ordered.size).to be == 3
		expect(chain.ordered[0].name).to be == "Variant/debug"
		expect(chain.ordered[1].name).to be == "Platform/generic"
		expect(chain.ordered[2].name).to be == "Test/TargetSpec"
		expect(chain.ordered[2].provider).to be == target
	end
	
	it "should match wildcard packages" do
		context = Teapot::Context.new(root)
		selection = context.select(["Test/*"])
		
		target = selection.targets["target_spec"]
		expect(target).not.to be_nil
		
		chain = selection.chain
		expect(chain.providers.size).to be == 4
		expect(chain.providers).to be(:include?, target)
	end
end
