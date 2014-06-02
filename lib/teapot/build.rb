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

require 'build/files'
require 'build/graph'

module Teapot
	Files = Build::Files
	
	module Build
		CommandFailure = FSO::Build::CommandFailure
		
		class Node < Build::Graph::Node
			def initialize(controller, rule, arguments, &block)
				@arguments = arguments
				@rule = rule
				
				@callback = block
				
				inputs, outputs = rule.files(arguments)
				
				super(controller, inputs, outputs)
			end
			
			attr :arguments
			attr :rule
			attr :callback
			
			def hash
				[@rule.name, @arguments].hash
			end
			
			def eql?(other)
				other.kind_of?(self.class) and @rule.eql?(other.rule) and @arguments.eql?(other.arguments)
			end
			
			def apply!(scope)
				@rule.apply!(task, @arguments)
				
				if @callback
					scope.instance_exec(@arguments, &@callback)
				end
			end
		end
		
		class Top < Build::Graph::Node
			def initialize(controller, task_class, &update)
				@update = update
				@task_class = task_class
				
				controller(graph, Files::None, Files::None)
			end
			
			attr :task_class
			
			def apply!(scope)
				scope.instance_eval(&@update)
			end
			
			# Top level nodes are always considered dirty. This ensures that enclosed nodes are run if they are dirty. The top level node has no inputs or outputs by default, so children who become dirty wouldn't mark it as dirty and thus wouldn't be run.
			def requires_update?
				true
			end
		end

		class Task < FSO::Build::Task
			def initialize(controller, walker, node, group = nil)
				super(controller, walker, node)
				
				@group = group
				
				if wet?
					@file_system = FileUtils
					#@file_system = FileUtils::Verbose
				else
					@file_system = FileUtils::NoWrite
				end
			end
			
			attr :file_system
			alias fs file_system
			
			def wet?
				@group and @node.dirty?
			end
			
			def update(rule, arguments, &block)
				arguments = rule.normalize(arguments)
				
				# A sub-graph for a particular build is isolated based on the task class used to instantiate it, so we use this as part of the key.
				child_node = @graph.nodes.fetch([self.class, rule.name, arguments]) do |key|
					@graph.nodes[key] = Node.new(@graph, rule, arguments, &block)
				end
				
				@children << child_node
				
				child_node.update!(@walker)
				
				return child_node.rule.result(arguments)
			end
			
			def wet?
				@pool and @node.dirty?
			end
			
			def run!(*arguments)
				if wet?
					# puts "Scheduling #{arguments.inspect}".color(:blue)
					status = @pool.spawn(*arguments)
					# puts "Finished #{arguments.inspect} with status #{status}".color(:blue)
					
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
		
		class Controller < Build::Graph::Controller
			def initialize
				@top = []
				
				yield self
				
				@top.freeze
				
				@task_class = nil
				
				super()
			end
			
			attr :top
			
			# Because we do a depth first traversal, we can capture global state per branch, such as `@task_class`.
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
				group = Process::Group.new
				
				super do |walker, node|
					@task_class.new(self, walker, node, pool)
				end
				
				group.wait
			end
		end
	end
end
