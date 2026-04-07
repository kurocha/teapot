# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "samovar"
require_relative "selection"
require "build/controller"

module Teapot
	module Command
		# A command to visualize dependency graphs.
		class Visualize < Samovar::Command
			self.description = "Generate visualizations of package and target dependencies."
			
			# Visualize package-level dependencies.
			class Packages < Selection
				self.description = "Visualize package-level dependencies from configuration.require."
				
				options do
					option "-o/--output-path <path>", "The output path for the visualization."
					option "-d/--dependency-name <name>", "Show the partial chain for the given named dependency."
				end
				
				# Get the specific dependency name to visualize.
				# @returns [String | Nil] The dependency name.
				def dependency_name
					@options[:dependency_name]
				end
				
				# Process and generate the package dependency visualization.
				# @parameter selection [Select] The selection to visualize.
				# @returns [String] The generated Mermaid diagram.
				def process(selection)
					chain = selection.chain
					
					if dependency_name
						provider = selection.dependencies[dependency_name]
						chain = chain.partial(provider)
					end
					
					visualization = ::Build::Dependency::Visualization.new
					diagram = visualization.generate(chain)
					
					if output_path = @options[:output_path]
						File.write(output_path, diagram)
					else
						$stdout.puts diagram
					end
					
					return diagram
				end
			end
			
			# Visualize target-level dependencies.
			class Targets < Selection
				self.description = "Visualize target-level dependencies from target.depends."
				
				options do
					option "-o/--output-path <path>", "The output path for the visualization."
				end
				
				# Process and generate the target dependency visualization.
				# @parameter selection [Select] The selection to visualize.
				# @returns [String] The generated Mermaid diagram.
				def process(selection)
					lines = ["flowchart LR"]
					lines << ""
					
					# Build the graph from all targets in the selection
					# The selection contains all targets loaded from packages
					selection.targets.each do |name, target|
						target.dependencies.each do |dependency|
							dependency_name = dependency.name.to_s
							
							# Create edge from target to its dependency
							if dependency.private?
								lines << "    #{sanitize_id(name)}[#{name}] -.-> #{sanitize_id(dependency_name)}[#{dependency_name}]"
							else
								lines << "    #{sanitize_id(name)}[#{name}] --> #{sanitize_id(dependency_name)}[#{dependency_name}]"
							end
						end
					end
					
					diagram = lines.join("\n")
					
					if output_path = @options[:output_path]
						File.write(output_path, diagram)
					else
						$stdout.puts diagram
					end
					
					return diagram
				end
				
				private
				
				# Convert a name to a valid Mermaid node ID.
				# @parameter name [String] The name to sanitize.
				# @returns [String] A sanitized identifier safe for use in Mermaid diagrams.
				def sanitize_id(name)
					name.to_s.gsub(/[^a-zA-Z0-9_]/, "_")
				end
			end
			
			# Visualize file-level dependencies from the build graph.
			class Files < Selection
				self.description = "Visualize file-level dependencies by walking the build graph."
				
				options do
					option "-o/--output-path <path>", "The output path for the visualization."
				end
				
				# Process and generate the file dependency visualization.
				# @parameter selection [Select] The selection to visualize.
				# @returns [String] The generated Mermaid diagram.
				def process(selection)
					require "build/graph/walker"
					require "build/graph/visualization"
					
					context = selection.context
					chain = selection.chain
					environment = context.configuration.environment
					
					# Build the controller to get the root nodes
					controller = ::Build::Controller.build(limit: 1) do |builder|
						builder.add_chain(chain, [], environment)
					end
					
					# Create a process group for task execution
					group = ::Process::Group.new
					
					# Create a walker that traverses without building
					walker = ::Build::Graph::Walker.new do |walker, node, parent_task = nil|
						task_class = node.task_class(parent_task) || ::Build::Graph::Task
						task = task_class.new(walker, node, group)
						
						# Use traverse instead of visit to skip building:
						task.traverse
					end
					
					# Populate the walker by traversing from the root nodes
					walker.update(controller.nodes)
					
					# Generate the Mermaid diagram
					visualization = ::Build::Graph::Visualization.new
					diagram = visualization.generate(walker)
					
					if output_path = @options[:output_path]
						File.write(output_path, diagram)
					else
						$stdout.puts diagram
					end
					
					return diagram
				end
			end
			
			nested :command, {
				"packages" => Packages,
				"targets" => Targets,
				"files" => Files,
			}, default: "packages"
			
			# Delegate context to parent Top command.
			# @returns [Context] The project context.
			def context
				parent.context
			end
			
			# Execute the visualize command.
			def call
				@command.call
			end
		end
	end
end
