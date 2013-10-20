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
		
		class Task
			def initialize(builder, rule, arguments)
				@builder = builder
				
				@parents = Set.new
				@rule = rule
				
				@arguments = @rule.normalize(arguments)
				
				@dirty = true
				@result = nil
				
				@tasks = {}
			end
			
			attr :tasks
			attr :parents
			
			def key
				[@rule.name, @arguments]
			end
			
			def hash
				key.hash
			end
			
			def eql?(other)
				key.eql? other.key
			end
			
			def mark
				unless @dirty
					@dirty = true
					@parent.mark
				end
			end
			
			def update
				if @dirty
					@result = @rule.apply!(@builder, @arguments)
				end
				
				return @result
			end
			
			def dump_tree(indent = 0)
				@tasks.each do |_, task|
					puts "#{"\t" * indent}Task: #{task.key}"
					task.dump_tree(indent+1)
				end
			end
		end
		
		class Builder
			def initialize(state = {})
				@state = state
				
				@graph = Teapot::Graph.new
				
				@stack = [self]
				
				@tasks = {}
			end
			
			def dump_tree
				@tasks.each do |_, task|
					puts "Builder: #{task.key}"
					task.dump_tree(1)
				end
			end
			
			attr :graph
			attr :tasks
			
			def with(state)
				old_state = @state
				@state = @state.merge(state)
			
				yield
			ensure
				@state = old_state
			end
			
			def update(rule, arguments)
				top = @stack.last
				
				task = Task.new(self, rule, arguments)
				
				# Get the current task:
				task = (@tasks[task] ||= task)
				task.parents << top
				
				@stack.push(task)
				begin
					result = task.update
				ensure
					@stack.pop
				end
				
				top.tasks[task] = task
				
				return result
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
	
		def with(state = {}, &block)
			rulebook = self
			builder = Builder.new(state)
			metaclass = class << builder; self; end
		
			@processes.each do |key, rules|
				# Define general rules, which use rule applicability for disambiguation:
				metaclass.send(:define_method, key) do |arguments|
					rule = rules.find{|rule| rule.applicable? arguments }
				
					if rule
						builder.update(rule, arguments)
					else
						raise NoApplicableRule.new(arguments)
					end
				end
			
				rules.each do |rule|
					metaclass.send(:define_method, rule.full_name) do |arguments|
						builder.update(rule, arguments)
					end
				end
			end
		
			builder.instance_eval(&block)
			
			builder.dump_tree
		end
	end
end
