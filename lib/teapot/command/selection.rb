# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "samovar"

module Teapot
	module Command
		# Base class for commands that work with selections.
		class Selection < Samovar::Command
			options
			
			many :targets, "Only consider the specified targets, if any."
			
			# The set of target names to process, or nil if no targets were specified.
			# @returns [Set | Nil] The set of target names.
			def targets
				if @targets and @targets.any?
					Set.new(@targets)
				end
			end
			
			# Get the selection for the given context.
			# @parameter context [Context] The project context.
			# @returns [Select] The selection.
			def selection(context)
				if targets = self.targets
					context.select(targets)
				else
					context.select(context.configuration[:build])
				end
			end
			
			# Execute the selection command.
			def call
				context = parent.context
				
				self.process(selection(parent.context))
			end
		end
	end
end
