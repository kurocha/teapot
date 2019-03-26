# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'selection'
require 'graphviz'

module Teapot
	module Command
		class Visualize < Selection
			self.description = "Generate a picture of the dependency graph."
			
			options do
				option '-o/--output-path <path>', "The output path for the visualization.", default: "dependency.svg"
				option '-d/--dependency-name <name>', "Show the partial chain for the given named dependency."
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
