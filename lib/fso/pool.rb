
require 'system'
require 'fiber'
require 'rainbow'

module FSO
	# A pool is a group of tasks which can be run asynchrnously using fibers. Someone must call #wait to ensure that all fibers eventuall resume.
	class Pool
		def self.processor_count
			System::CPU.count
		end
	
		class Command
			def initialize(arguments, options, fiber = Fiber.current)
				@arguments = arguments
				@options = options
				
				@fiber = fiber
			end
			
			attr :arguments
			attr :options
			
			def run(options = {})
				puts "Running #{@arguments.inspect} options: #{@options.merge(options).inspect}".color(:blue)
				
				Process.spawn(*@arguments, @options.merge(options))
			end
			
			def resume(*arguments)
				@fiber.resume(*arguments)
			end
		end
	
		def initialize(options = {})
			@commands = []
			@limit = options[:limit] || Pool.processor_count
			
			@running = {}
			@fiber = nil
			
			@pgid = true
		end
		
		attr :running
		
		def run(*arguments)
			options = Hash === arguments.last ? arguments.pop : {}
			arguments = arguments.flatten.collect &:to_s
			
			@commands << Command.new(arguments, options)
			
			schedule!
			
			Fiber.yield
		end
		
		def schedule!
			while @running.size < @limit and @commands.size > 0
				command = @commands.shift
				
				if @running.size == 0
					pid = command.run(:pgroup => true)
					@pgid = Process.getpgid(pid)
				else
					pid = command.run(:pgroup => @pgid)
				end
				
				@running[pid] = command
			end
		end
	
		def wait
			while @running.size > 0
				# Wait for processes in this group:
				pid, status = Process.wait2(-@pgid)
				
				command = @running.delete(pid)
				
				schedule!
				
				command.resume(status)
			end
		end
	end
	
	module FakePool
		def self.wait
		end
		
		def self.run(*arguments)
			0
		end
	end
end
