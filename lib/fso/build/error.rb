
module FSO
	module Build
		class TransientError < StandardError
		end
		
		class CommandFailure < TransientError
			def initialize(command, status)
				super "Command #{command.inspect} failed with exit status #{status}!"
			
				@command = command
				@status = status
			end
		
			attr :command
			attr :status
		end
	end
end
