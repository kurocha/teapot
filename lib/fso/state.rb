
module FSO
	class State
		def initialize(files)
			@files = files
		
			@times = {}
		
			update!
		end
	
		attr :files
	
		attr :added
		attr :removed
		attr :changed
		
		attr :times
		
		def update!
			last_times = @times
			@times = {}
		
			@added = []
			@removed = []
			@changed = []
		
			@files.each do |path|
				next unless File.exist?(path)
					
				modified_time = File.mtime(path)
				
				if last_time = last_times.delete(path)
					# Path was valid last update:
					if modified_time != last_time
						@changed << path
					end
				else
					# Path didn't exist before:
					@added << path
				end
			
				@times[path] = modified_time
			end
		
			@removed = last_times.keys
		
			return @added.size > 0 || @changed.size > 0 || @removed.size > 0
		end
		
		def oldest_time
			@times.values.min
		end
		
		def newest_time
			@times.values.max
		end
		
		def missing?
			@times.values.include?(nil)
		end
		
		# Outputs must not include any patterns/globs.
		def intersects?(outputs)
			@files.intersects?(outputs)
		end
	end
	
	class IOState
		def initialize(inputs, outputs)
			@input_state = State.new(inputs)
			@output_state = State.new(outputs)
		end
		
		attr :input_state
		attr :output_state
		
		def fresh?
			return false if @output_state.missing?
			
			oldest_output_time = @output_state.oldest_time
			newest_input_time = @input_state.newest_time
			
			if oldest_output_time and newest_input_time
				# We are fresh if the oldest output time is in the future compared to the newest input time.
				return oldest_output_time > newest_input_time
			else
				return false
			end
		end
		
		def files
			@input_state.files + @output_state.files
		end
		
		def added
			@input_state.added + @output_state.added
		end
		
		def removed
			@input_state.removed + @output_state.removed
		end
		
		def changed
			@input_state.changed + @output_state.changed
		end
		
		def update!
			input_changed = @input_state.update!
			output_changed = @output_state.update!
			
			input_changed or output_changed
		end
		
		def intersects?(outputs)
			@input_state.intersects?(outputs) or @output_state.intersects?(outputs)
		end
	end
	
	class Handle
		def initialize(monitor, files, &block)
			@monitor = monitor
			@state = State.new(files)
			@on_changed = block
		end
		
		attr :monitor
		
		def commit!
			@state.update!
		end
		
		def directories
			@state.files.roots
		end
		
		def remove!
			monitor.delete(self)
		end
		
		def changed!
			@on_changed.call(@state) if @state.update!
		end
	end
end
