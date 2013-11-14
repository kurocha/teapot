
require 'set'

require 'fso/files'
require 'fso/state'

module FSO
	class Monitor
		def initialize
			@directories = Hash.new { |hash, key| hash[key] = Set.new }
			
			@updated = false
		end
		
		attr :updated
		
		# Notify the monitor that files in these directories have changed.
		def update(directories, *args)
			directories.each do |directory|
				directory = File.realpath(directory)
				@directories[directory].each do |handle|
					handle.changed!(*args)
				end
			end
		end
		
		def roots
			@directories.keys
		end
		
		def delete(handle)
			handle.directories.each do |directory|
				@directories[directory].delete(handle)
				
				# Remove the entire record if there are no handles:
				if @directories[directory].size == 0
					@directories.delete(directory)
					
					@updated = true
				end
			end
		end
		
		def track_changes(files, &block)
			handle = Handle.new(self, files, &block)
			
			add(handle)
		end
		
		def add(handle)
			handle.directories.each do |directory|
				@directories[directory] << handle
				
				# We just added the first handle:
				if @directories[directory].size == 1
					# If the handle already existed, this might trigger unnecessarily.
					@updated = true
				end
			end
			
			handle
		end
	end
	
	def self.run_with_fsevent(monitor, options = {}, &block)
		require 'rb-fsevent'
		
		fsevent ||= FSEvent.new
		
		catch(:interrupt) do
			while true
				fsevent.watch monitor.roots do |directories|
					monitor.update(directories)
					
					yield
					
					if monitor.updated
						fsevent.stop
					end
				end
				
				fsevent.run
			end
		end
	end
	
	def self.run_with_polling(monitor, options = {}, &block)
		catch(:interrupt) do
			while true
				monitor.update(monitor.roots)
				
				yield
				
				sleep(options[:latency] || 5.0)
			end
		end
	end
	
	def self.run(monitor, options = {}, &block)
		run_with_polling(monitor, options, &block)
	end
end
