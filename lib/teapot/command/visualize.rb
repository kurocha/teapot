# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require_relative "selection"
require "graphviz"

module Teapot
	module Command
		# A command to visualize the dependency graph.
		class Visualize < Selection
			self.description = "Generate a picture of the dependency graph."
			
			options do
				option "-o/--output-path <path>", "The output path for the visualization.", default: "dependency.svg"
				option "-d/--dependency-name <name>", "Show the partial chain for the given named dependency."
			end
			
			# Get the dependency names to visualize.
			# @returns [Array(String)] The dependency names.
			def dependency_names
				@targets || []
			end
			
			# Get the specific dependency name to visualize.
			# @returns [String | Nil] The dependency name.
			def dependency_name
				@options[:dependency_name]
			end
			
			# Process and generate the visualization.
			# @parameter selection [Select] The selection to visualize.
			# @returns [Graphviz::Graph] The generated graph.
			def process(selection)
				context = selection.context
				chain = selection.chain
				
				if dependency_name
					provider = selection.dependencies[dependency_name]
					
					chain = chain.partial(provider)
				end
				
				visualization = ::Build::Dependency::Visualization.new
				
				graph = visualization.generate(chain)
				
				if output_path = @options[:output_path]
					Graphviz.output(graph, path: output_path, format: :svg)
				else
					$stdout.puts graph.to_dot
				end
				
				return graph
			end
		end
	end
end
