
require 'set'

module FSO
	module Build
		class Walker
			def initialize(graph, &task)
				@graph = graph
				@task = task
				
				@count = 0
				
				@outputs = {}
				@dirty = Set.new
				
				# Generate a list of dirty outputs, possibly a subset, if the build graph might generate additional nodes:
				@graph.nodes.each do |key, node|
					# For a given child, a list of any parents waiting on it.
					if node.dirty?
						@dirty << node
						
						@outputs[node] = []
						
						node.outputs.each do |output|
							@outputs[output] = []
						end
					end
				end
				
				@parents = {}
				
				# Failed output paths:
				@failed = Set.new
			end
			
			attr :graph
			attr :output
			
			attr_accessor :count
			
			attr :dirty
			attr :parents
			
			def task(*arguments)
				@task.call(self, *arguments)
			end
			
			def wait_on_paths(paths)
				edge = Edge.new
				failed = false
				
				paths.each do |path|
					if @outputs.include? path
						@outputs[path] << edge
						
						edge.increment!
					end
					
					if !failed and @failed.include?(path)
						failed = true
					end
				end
				
				edge.wait || failed
			end
			
			def wait_for_nodes(children)
				edge = Edge.new
				
				children.each do |child|
					if @dirty.include?(child)
						edge.increment!
						
						@parents[child] ||= []
						@parents[child] << edge
					end
				end
				
				edge.wait
			end
			
			def exit(node)
				@dirty.delete(node)
				
				# Fail outputs if the node failed:
				@failed += node.outputs if node.failed?
				
				# Clean the node's outputs:
				node.outputs.each do |path|
					if edges = @outputs.delete(path)
						edges.each{|edge| edge.traverse(node)}
					end
				end
			
				# Trigger the parent nodes:
				if parents = @parents.delete(node)
					parents.each{|edge| edge.traverse(node)}
				end
			end
		end
		
		class Task
			def initialize(graph, node, walker, pool = nil)
				@graph = graph
				@node = node
				@walker = walker
				@pool = pool
				
				# If the execution of the node fails, this is where we save the error:
				@error = nil
				
				@children = []
			end
		
			def process(inputs, outputs, &block)
				child_node = @graph.nodes.fetch([inputs, outputs]) do |key|
					@graph.nodes[key] = Node.new(@graph, inputs, outputs, &block)
				end
			
				@children << child_node
			
				# State saved in update!
				child_node.update!(@walker)
			end
		
			def run(*arguments)
				if @pool and @node.dirty?
					status = @pool.run(*arguments)
					
					if status != 0
						raise CommandFailure.new(arguments, status)
					end
				end
			end
		
			def inputs
				@node.inputs
			end
		
			def outputs
				@node.outputs
			end
			
			def visit(update)
				# Wait on any inputs, returns whether any inputs failed:
				@inputs_failed = @walker.wait_on_paths(@node.inputs)
				
				# If all inputs were good, we can update the node.
				unless @inputs_failed
					begin
						self.instance_eval(&update)
					rescue TransientError => error
						$stderr.puts "Error: #{error.inspect}".color(:red)
						@error = error
					end
				end
				
				@walker.wait_for_nodes(@children)
			end
			
			def any_child_failed?
				@children.any?{|child| child.failed?}
			end
			
			def any_inputs_failed?
				@inputs_failed
			end
			
			def exit
				if @error || any_child_failed? || any_inputs_failed?
					@node.fail!
				elsif @pool
					@node.clean!
				end
				
				@walker.exit(@node)
				
				@walker.count += 1
			end
		end
	end
end
