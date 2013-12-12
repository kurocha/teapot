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

require 'teapot/rule'

require 'fso/monitor'
require 'fso/files'

require 'fso/build/graph'

module Teapot
	module Build
		Files = FSO::Files
		CommandFailure = FSO::Build::CommandFailure
		
		class Node < FSO::Build::Node
			def initialize(graph, rule, arguments)
				@arguments = arguments
				@rule = rule
		
				inputs, outputs = rule.files(arguments)
		
				super(graph, inputs, outputs)
			end
	
			attr :arguments
			attr :rule
	
			def hash
				[@rule.name, @arguments].hash
			end
	
			def eql?(other)
				other.kind_of?(self.class) and @rule.eql?(other.rule) and @arguments.eql?(other.arguments)
			end
	
			def apply!(scope)
				puts "Invoking rule #{rule.name} with arguments #{@arguments.inspect}"
				@rule.apply!(scope, @arguments)
			end
		end
		
		class Top < FSO::Build::Node
			def initialize(graph, task_class, &update)
				@update = update
				@task_class = task_class
				
				super(graph, Files::paths, Files::paths)
			end
			
			attr :task_class
			
			def apply!(scope)
				scope.instance_eval(&@update)
			end
			
			# Top level nodes are always considered dirty. This ensures that enclosed nodes are run if they are dirty. The top level node has no inputs or outputs by default, so children who become dirty wouldn't mark it as dirty.
			def requires_update?
				true
			end
		end

		class Task < FSO::Build::Task
			def initialize(graph, walker, node, pool = nil)
				@pool = pool
				
				super(graph, walker, node)
			end
	
			def update(rule, arguments, &block)
				arguments = rule.normalize(arguments)
		
				child_node = @graph.nodes.fetch([rule.name, arguments]) do |key|
					@graph.nodes[key] = Node.new(@graph, rule, arguments, &block)
				end
		
				@children << child_node
		
				child_node.update!(@walker)
		
				return child_node.rule.result(arguments)
			end
	
			def run!(*arguments)
				if @pool and @node.dirty?
					status = @pool.run(*arguments)
			
					if status != 0
						raise CommandFailure.new(arguments, status)
					end
				end
			end
	
			def visit
				super do
					@node.apply!(self)
				end
			end
		end
	
		class Graph < FSO::Build::Graph
			def initialize
				@top = []
				
				yield self
				
				@top.freeze
				
				@task_class = nil
				
				super()
			end
			
			attr :top
			
			def traverse!(walker)
				@top.each do |node|
					# Capture the task class for each top level node:
					@task_class = node.task_class
					
					node.update!(walker)
				end
			end
			
			def add_target(target, environment, &block)
				task_class = Rulebook.for(environment).with(Task, environment: environment, target: target)
				
				@top << Top.new(self, task_class, &target.build)
			end
			
			def build_graph!
				super do |walker, node|
					@task_class.new(self, walker, node)
				end
			end
			
			def update!
				pool = FSO::Pool.new
				
				super do |walker, node|
					@task_class.new(self, walker, node, pool)
				end
				
				pool.wait
			end
		end
	end
end
