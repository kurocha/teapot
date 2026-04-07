# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "samovar"

module Teapot
	module Command
		# A command to clean build artifacts.
		class Clean < Samovar::Command
			self.description = "Delete everything in the teapot directory."
			
			# Delete build output directories for the specified targets or all targets.
			def call
				context = parent.context
				logger = parent.logger
				configuration = context.configuration
				
				logger.info "Removing #{configuration.build_path}..."
				FileUtils.rm_rf configuration.build_path
				
				logger.info "Removing #{configuration.packages_path}..."
				FileUtils.rm_rf configuration.packages_path
			end
		end
	end
end
