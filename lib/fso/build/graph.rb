
require 'fso/monitor'
require 'fso/pool'

require 'fso/build/error'
require 'fso/build/node'
require 'fso/build/walker'
require 'fso/build/edge'

module FSO
	module Build
		class Graph < Monitor
			def initialize(&block)
				super
			
				@nodes = {}
			
				@update = block
			
				build_graph!
			end
		
			attr :nodes
		
			def top
				Node.new(self, paths(), paths(), &@update)
			end
		
			def build_graph!
				puts "*** Initial graph traversal ***".color(:green)
				# We build the graph without doing any actual execution:
			
				nodes = []
			
				walker = Walker.new(self) do |walker, node|
					nodes << node
				
					Task.new(self, node, walker)
				end
			
				top.update!(walker)
			
				# We should update the status of all nodes in the graph once we've traversed the graph.
				nodes.each do |node|
					node.update_status!
				end
			end
		
			def update!
				puts "*** Graph update traversal ***".color(:green)
			
				start_time = Time.now
			
				pool = Pool.new
			
				walker = Walker.new(self) do |walker, node|
					Task.new(self, node, walker, pool)
				end
			
				top.update!(walker)
			
				pool.wait
			ensure
				end_time = Time.now
				elapsed_time = end_time - start_time
			
				if walker.count > 0
					$stdout.flush
					$stderr.puts ("Graph Update Time: %0.3fs" % elapsed_time).color(:magenta)
				end
			end
		end
	end
end
