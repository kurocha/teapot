
require 'fso/monitor'
require 'fso/pool'

require 'fso/build/error'
require 'fso/build/node'
require 'fso/build/walker'
require 'fso/build/edge'

module FSO
	module Build
		class Graph < Monitor
			def initialize
				super
				
				@nodes = {}
				
				build_graph!
			end
			
			attr :nodes
			
			def top
				raise NotImplementedError
			end
			
			def walk(&block)
				Walker.new(self, &block)
			end
			
			def build_graph!
				# We build the graph without doing any actual execution:
				nodes = []
				
				walker = walk do |walker, node|
					nodes << node
					
					yield walker, node
				end
				
				top.update!(walker)
				
				# We should update the status of all nodes in the graph once we've traversed the graph.
				nodes.each do |node|
					node.update_status!
				end
			end
			
			def update_with_log
				puts "*** Graph update traversal ***".color(:green)
				
				start_time = Time.now
				
				walker = update!
				
			ensure
				end_time = Time.now
				elapsed_time = end_time - start_time
				
				if walker.count > 0
					$stdout.flush
					$stderr.puts ("Graph Update Time: %0.3fs" % elapsed_time).color(:magenta)
				end
			end
			
			def update!
				walker = walk do |walker, node|
					yield walker, node
				end
				
				top.update!(walker)
				
				return walker
			end
		end
	end
end
