
module FSO
	module Build
		class Node
			def initialize(graph, inputs, outputs, &block)
				@graph = graph
				
				@state = IOState.new(inputs, outputs)
				
				@status = :unknown
				@fiber = nil
				
				# These are immutable - rather than change them, create a new node:
				@inputs = inputs
				@outputs = outputs
				
				@update = block
				
				@graph.add(self)
			end
			
			def eql?(other)
				other.kind_of?(self.class) and @inputs.eql?(other.inputs) and @outputs.eql?(other.outputs)
			end
			
			def hash
				[@inputs, @outputs].hash
			end
			
			def directories
				@state.files.roots
			end
			
			def remove!
				@graph.delete(self)
			end
			
			# It is possible this function is called unnecessarily. The state check confirms whether a change occurred or not.
			def changed!(outputs = [])
				# Don't do anything if we are already dirty.
				return if dirty?
			
				if @state.intersects?(outputs) || @state.update!
					#puts "changed: inputs=#{inputs} #{@inputs.to_a.inspect} -> #{@outputs.to_a.inspect}"
				
					# Could possibly use unknown status here.
					@status = :dirty
				
					# If this node changes, we force all other nodes which depend on this node to be dirty.
					@graph.update(directories, @outputs)
				end
			end
		
			attr :inputs
			attr :outputs
		
			attr :children
		
			attr :state
			attr :status
		
			def unknown?
				@status == :unknown
			end
		
			def dirty?
				@status == :dirty
			end
		
			def clean?
				@status == :clean
			end
		
			def clean!
				@status = :clean
			end
			
			def fail!
				@status = :failed
			end
			
			def failed?
				@status == :failed
			end
			
			def updating?
				@fiber != nil
			end
			
			# If we are in the initial state, we need to check if the outputs are fresh.
			def update_status!
				# puts "Update status: #{@inputs.to_a.inspect} -> #{@outputs.to_a.inspect} (dirty=#{dirty?} @fiber=#{@fiber.inspect}) @status=#{@status}"
				
				if @status == :unknown
					# This could be improved - only stale files should be reported, instead we report all.
					unless @state.fresh?
						changed!(self.inputs)
					else
						@status = :clean
					end
				end
			end
			
			def inspect
				"<#{dirty? ? '*' : ''}inputs=#{inputs.inspect} outputs=#{outputs.inspect} fiber=#{@fiber.inspect}>"
			end
			
			# Perform some actions to update this node, returns when completed, and the node is no longer dirty.
			def update!(walker)
				# puts "Walking #{@inputs.to_a.inspect} -> #{@outputs.to_a.inspect} (dirty=#{dirty?} @fiber=#{@fiber.inspect})"
				
				# If a fiber already exists, this node is in the process of updating.
				if not clean? and @fiber == nil
					# puts "Beginning: #{@inputs.to_a.inspect} -> #{@outputs.to_a.inspect}"
					
					@fiber = Fiber.new do
						task = walker.task(self)
						
						task.visit(@update)
						
						# Commit changes:
						# puts "Committing: #{@inputs.to_a.inspect} -> #{@outputs.to_a.inspect}"
						@state.update!
						@fiber = nil
						
						task.exit
					end
				
					@fiber.resume
				end
			end
		end
	end
end
