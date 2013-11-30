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
require 'fso/build/graph'

module Teapot
	class Rulebook
		def initialize
			@rules = {}
			@processes = {}
		end
	
		def << rule
			@rules[rule.name] = rule
		
			# A cache for fast process/file-type lookup:
			processes = @processes[rule.process_name] ||= []
			processes << rule
		end

		def [] name
			@rules[name]
		end
		
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
				@rule.apply!(scope, @arguments)
			end
		end
		
		class Top < FSO::Build::Node
			def initialize(graph, &update)
				@update = update
				
				super(graph, paths(), paths())
			end
			
			def apply!(scope)
				scope.instance_eval(&@update)
			end
		end
		
		class Task < FSO::Build::Task
			def initialize(graph, walker, node, state, pool = nil)
				@state = state
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
			
			def run(*arguments)
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
			
			def with(state)
				old_state = @state
				@state = @state.merge(state)
			
				yield
			ensure
				@state = old_state
			end
			
			def method_missing(name)
				if @state.key? name
					@state[name]
				else
					super
				end
			end
		
			def respond_to?(name)
				if @state.key? name.to_sym
					true
				else
					super
				end
			end
		end
		
		class Builder < FSO::Build::Graph
			def initialize(initial_state, task_class, &block)
				@initial_state = initial_state
				@task_class = task_class
				
				@update = block
				
				super()
			end
			
			def top
				Top.new(self, &@update)
			end
			
			def build_graph!
				super do |walker, node|
					@task_class.new(self, walker, node, @initial_state)
				end
			end
			
			def update!
				pool = FSO::Pool.new
				
				super do |walker, node|
					@task_class.new(self, walker, node, @initial_state, pool)
				end
				
				pool.wait
			end
		end
		
		def with(state = {}, &block)
			task_class = Class.new(Task)
			
			@processes.each do |key, rules|
				# Define general rules, which use rule applicability for disambiguation:
				task_class.send(:define_method, key) do |arguments, &block|
					rule = rules.find{|rule| rule.applicable? arguments }
					
					if rule
						update(rule, arguments, &block)
					else
						raise NoApplicableRule.new(arguments)
					end
				end
				
				rules.each do |rule|
					task_class.send(:define_method, rule.full_name) do |arguments, &block|
						update(rule, arguments, &block)
					end
				end
			end
			
			builder = Builder.new(state, task_class, &block)
			
			return builder
		end
	end
end
