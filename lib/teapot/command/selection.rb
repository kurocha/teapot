# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "samovar"

module Teapot
	module Command
		class Selection < Samovar::Command
			options
			
			many :targets, "Only consider the specified targets, if any."
			
			def targets
				if @targets and @targets.any?
					Set.new(@targets)
				end
			end
			
			def selection(context)
				if targets = self.targets
					context.select(targets)
				else
					context.select(context.configuration[:build])
				end
			end
			
			def call
				context = parent.context
				
				self.process(selection(parent.context))
			end
		end
	end
end
