
require 'fso/build/error'

module FSO
	module Build
		# Represents an input to a graph node, with count inputs.
		class Edge
			def initialize(count = 0)
				@fiber = Fiber.current
				@count = count
				
				@failed = []
			end
			
			attr :failed
			
			attr :fiber
			attr :count
			
			def wait
				if @count > 0
					Fiber.yield
				end
				
				failed?
			end
			
			attr :failed
			
			def failed?
				@failed.size != 0
			end
			
			def traverse(node)
				@count -= 1
				
				if node.failed?
					@failed << node
				end
				
				if @count == 0
					@fiber.resume
				end
			end
			
			def increment!
				@count += 1
			end
		end
	end
end
