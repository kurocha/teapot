# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'set'
require 'pathname'

module Teapot
	class Graph
		def initialize
			@nodes = {}

			@extractors = []
		end

		attr :root
		attr :nodes
		attr :extractors

		def << node
			@nodes[node.path] = node
		end

		def regenerate?(output_path, input_paths)
			return true unless output_path.exist?

			output_modified_time = output_path.mtime

			Array(input_paths).each do |path|
				node = fetch(path)

				return true if node.changed_since?(output_modified_time)
			end

			return false
		end

		def extract(source_path)
			dependencies = Set.new

			@extractors.each do |extractor|
				extractor.call(source_path) do |path|
					dependencies << path
				end
			end

			nodes = dependencies.map{|path| fetch(path)}
		end

		def Node(path)
			Node.new(self, path)
		end

		def fetch(path)
			@nodes.fetch(path) do
				node = @nodes[path] = Node(path)

				node.extract_dependencies!

				node
			end
		end

		class Node
			def initialize(graph, path)
				@graph = graph

				@path = Pathname(path)

				@dependencies = []

				@changed = nil
			end

			attr :path
			attr :dependencies

			def all_dependencies
				@dependencies || []
			end

			def changed_since?(modified_time)
				return true unless @path.exist?

				if @changed == nil
					# If the file was modified in the future relative to old modified_time:
					if @path.mtime > modified_time
						puts "Changed: #{path.to_s.inspect}"
						return @changed = true
					else
						@changed = false
					end

					# If any of the file's dependencies have changed relative to the old modified_time:
					all_dependencies.each do |dependency|
						if dependency.changed_since?(modified_time)
							return @changed = true
						end
					end
				end

				return @changed
			end

			def extract_dependencies!
				@dependencies = @graph.extract(path)
			end
		end

		class Extractor
			def initialize(patterns = [])
				@patterns = Array(patterns)
			end

			def extract(path)
			end

			def call(path, &block)
				return unless path.exist?
				
				basename = path.basename.to_s

				if @patterns.find{|pattern| pattern.match(basename)}
					extract(path, &block)
				end
			end
		end
	end
end
