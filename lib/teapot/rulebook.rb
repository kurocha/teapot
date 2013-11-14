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
			include Enumerable
			
			def initialize(builder, rule, arguments)
				@builder = builder
				
				@parents = Set.new
				@rule = rule
				
				@arguments = @rule.normalize(arguments)
				
				@dirty = true
				@result = nil
				
				@inputs = FSO::Files::Composite.new
				@outputs = FSO::Files::Composite.new
				
				@tasks = {}
				
				@inputs_handle = nil
				@outputs_handle = nil
			end
			
			attr :rule
			attr :arguments
			
			attr :tasks
			attr :parents
			
			attr :inputs
			attr :outputs
			
			def hash
				[@rule.name, @arguments].hash
			end
			
			def eql?(other)
				other.kind_of?(self.class) and @rule.eql?(other.rule) and @arguments.eql?(other.arguments)
			end
			
			# Mark this task as dirty, and all tasks which depend on this task.
			def mark!
				unless @dirty
					@dirty = true
					@parents.each &:mark!
				end
			end
			
			def purge!
				@parents.each do |parent|
					parent.tasks.delete(self)
				end
			end
			
			# Returns true if all inputs and outputs exist, and all outputs are up-to-date.
			def clean?
				return false unless @inputs.all?{|path| File.exist?(path)}
				return false unless @outputs.all?{|path| File.exist?(path)}
				
				input_mtime = @inputs.collect{|path| File.mtime(path)}.max
				output_mtime = @outputs.collect{|path| File.mtime(path)}.min
				
				return output_mtime >= input_mtime
			end
			
			def dirty?
				@dirty
			end
			
			# Run the associated rule which would then make this task clean.
			def update
				if @dirty
					@result = @rule.apply!(@builder, @arguments)
					
					puts "Cleaning #{self}"
					@dirty = false
					
					@outputs_handle.commit! if @outputs_handle
				end
				
				return @result
			end
			
			# Call self.mark! if any input files changed.
			def track_changes(monitor)
				return if @inputs_handle
				
				# If your inputs change, you are dirty:
				@inputs_handle = monitor.track_changes(@inputs) do |state|
					puts "State #{state.inspect} for #{@rule.name}"
					# Sometimes the filesystem events come in due to own changes, but in this case we don't want to rebuild.
					self.mark!
				end
				
				# If your output changes after you've committed your update, you are now old. Being old means someone else has taken over the responsibility for your outputs, and thus you will be removed, as you are no longer relevant.
				@outputs_handle = monitor.track_changes(@outputs) do |state|
					self.mark!
				end
			end
			
			def dump_tree(indent = 0)
				@tasks.each do |_, task|
					puts "#{"\t" * indent}#{task}"
					task.dump_tree(indent+1)
				end
			end
			
			def to_s
				"<#{@dirty ? '*' : ''}#{@rule.name}(#{@arguments})>"
			end
		end
		
		class Builder
			def initialize(state = {}, graph, &block)
				@state = state
				
				@monitor = FSO::Monitor.new
				
				@stack = [self]
				@tasks = {}
				
				@build = block
			end
			
			def dump_tree
				@tasks.each do |_, task|
					puts "#{task}"
					task.dump_tree(1)
				end
			end
			
			attr :graph
			attr :tasks
			
			attr :monitor
			
			def with(state)
				old_state = @state
				@state = @state.merge(state)
			
				yield
			ensure
				@state = old_state
			end
			
			def mark!
			end
			
			def update(rule, arguments, &block)
				top = @stack.last
				
				task = Task.new(self, rule, arguments)
				
				# Get the current task:
				task = (@tasks[task] ||= task)
				task.parents << top
				
				@stack.push(task)
				begin
					# Ensure dependent tasks are run first:
					yield task if block_given?
					
					# Then run current task:
					result = task.update
					
					task.track_changes(@monitor)
				ensure
					@stack.pop
				end
				
				top.tasks[task] = task
				
				return result
			end
			
			def fresh?(input_paths, output_paths)
				top = @stack.last
				
				top.inputs.merge(input_paths)
				top.outputs.merge(output_paths)
				
				return false
			end
			
			def prune!
				@tasks.delete_if do |_, task|
					task.dirty? and (task.purge! || true)
				end
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
			
			def build!
				start_time = Time.now

				self.instance_eval(&@build)
				
				self.prune!
			ensure
				end_time = Time.now
				elapsed_time = end_time - start_time

				$stdout.flush
				$stderr.puts ("Build Graph Time: %0.3fs" % elapsed_time).color(:magenta)
			end
		end
		
		def with(state = {}, graph = Graph.new, &block)
			rulebook = self
			builder = Builder.new(state, graph, &block)
			metaclass = class << builder; self; end
			
			@processes.each do |key, rules|
				# Define general rules, which use rule applicability for disambiguation:
				metaclass.send(:define_method, key) do |arguments, &block|
					rule = rules.find{|rule| rule.applicable? arguments }
					
					if rule
						builder.update(rule, arguments, &block)
					else
						raise NoApplicableRule.new(arguments)
					end
				end
				
				rules.each do |rule|
					metaclass.send(:define_method, rule.full_name) do |arguments, &block|
						builder.update(rule, arguments, &block)
					end
				end
			end
			
			return builder
		end
	end
end
