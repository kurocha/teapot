# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require_relative "selection"

require "build/controller"

module Teapot
	module Command
		# Raised when the build fails.
		class BuildFailedError < StandardError
		end
		
		# A command to build targets in the project.
		class Build < Selection
			self.description = "Build the specified target."
			
			options do
				option "-j/-l/--limit <n>", "Limit the build to <n> concurrent processes.", type: Integer
				option "-c/--continuous", "Run the build graph continually (experimental)."
				option "--show-dependencies", "Show task dependencies for debugging."
			end
			
			many :targets, "Build these targets, or use them to help the dependency resolution process."
			split :argv, "Arguments passed to child process(es) of build if any."
			
			# Build the selected targets or default build targets, resolving dependencies and executing the build controller.
			# @returns [Build::Dependency::Chain] The dependency chain.
			def call
				context = parent.context
				
				# The targets to build:
				if @targets.any?
					selection = context.select(@targets)
				else
					selection = context.select(context.configuration.targets[:build])
				end
				
				chain = selection.chain
				environment = context.configuration.environment
				
				controller = ::Build::Controller.build(limit: @options[:limit]) do |builder|
					builder.add_chain(chain, self.argv, environment)
				end
				
				walker = nil
				
				# We need to catch interrupt here, and exit with the correct exit code:
				begin
					controller.run do |walker|
						show_dependencies(walker) if @options[:show_dependencies]
						
						# Only run once is asked:
						unless @options[:continuous]
							if walker.failed?
								raise BuildFailedError.new("Failed to build all nodes successfully!")
							end
							
							break
						end
					end
				rescue Interrupt
					if walker && walker.failed?
						raise BuildFailedError.new("Failed to build all nodes successfully!")
					end
				end
				
				return chain
			end
			
			# Display task dependencies for debugging, showing which tasks generate which outputs.
			# @parameter walker [Build::Walker] The build walker.
			def show_dependencies(walker)
				outputs = {}
				
				walker.tasks.each do |node, task|
					# puts "Task #{task} (#{node}) outputs:"
					
					task.outputs.each do |path|
						path = path.to_s
						
						# puts "\t#{path}"
						
						outputs[path] = task
					end
				end
				
				walker.tasks.each do |node, task|
					dependencies = {}
					task.inputs.each do |path|
						path = path.to_s
						
						if generating_task = outputs[path]
							dependencies[path] = generating_task
						end
					end
					
					puts "Task #{task.inspect} has #{dependencies.count} dependencies."
					dependencies.each do |path, task|
						puts "\t#{task.inspect}: #{path}"
					end
				end
			end
		end
	end
end
