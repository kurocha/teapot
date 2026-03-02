# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require_relative "selection"
require "graphviz"

module Teapot
	module Command
		class Visualize < Selection
			self.description = "Generate a picture of the dependency graph."
			
			options do
				option "-o/--output-path <path>", "The output path for the visualization.", default: "dependency.svg"
				option "-d/--dependency-name <name>", "Show the partial chain for the given named dependency."
			end
			
			def dependency_names
				@targets || []
			end
			
			def dependency_name
				@options[:dependency_name]
			end
			
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
