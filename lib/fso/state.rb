
module FSO
	class FileTime
		include Comparable
		
		def initialize(path, time)
			@path = path
			@time = time
		end
		
		attr :path
		attr :time
		
		def <=> other
			@time <=> other.time
		end
	end
	
	class State
		def initialize(files)
			raise ArgumentError.new("Invalid files list: #{files}") unless Files::List === files
			
			@files = files
		
			@times = {}
			
			update!
		end
	
		attr :files
	
		attr :added
		attr :removed
		attr :changed
		attr :missing
		
		attr :times
		
		def update!
			last_times = @times
			@times = {}
			
			@added = []
			@removed = []
			@changed = []
			@missing = []
			
			file_times = []
			
			@files.each do |path|
				if File.exist?(path)
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
					
					unless File.directory?(path)
						file_times << FileTime.new(path, modified_time)
					end
				else
					@missing << path
				end
			end
			
			@removed = last_times.keys
			
			@oldest_time = file_times.min
			@newest_time = file_times.max
			
			return @added.size > 0 || @changed.size > 0 || @removed.size > 0
		end
		
		attr :oldest_time
		attr :newest_time
		
		attr :missing
		
		def missing?
			!@missing.empty?
		end
		
		# Outputs is a list of full paths and must not include any patterns/globs.
		def intersects?(outputs)
			@files.intersects?(outputs)
		end
		
		def empty?
			@files.to_a.empty?
		end
	end
	
	class IOState
		def initialize(inputs, outputs)
			@input_state = State.new(inputs)
			@output_state = State.new(outputs)
		end
		
		attr :input_state
		attr :output_state
		
		# Output is dirty if files are missing or if latest input is older than any output.
		def dirty?
			if @output_state.missing?
				# puts "Output file missing: #{output_state.missing.inspect}"
				
				return true
			end
			
			# If there are no inputs, we are always clean as long as outputs exist:
			# if @input_state.empty?
			#	return false
			# end
			
			oldest_output_time = @output_state.oldest_time
			newest_input_time = @input_state.newest_time
			
			if newest_input_time and oldest_output_time
				# if newest_input_time > oldest_output_time
				#	puts "Out of date file: #{newest_input_time.inspect} > #{oldest_output_time.inspect}"
				# end
				
				return newest_input_time > oldest_output_time
			end
			
			# puts "Missing file dates: #{newest_input_time.inspect} < #{oldest_output_time.inspect}"
			
			return true
		end
		
		def fresh?
			not dirty?
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
