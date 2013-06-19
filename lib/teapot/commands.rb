# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'set'
require 'rainbow'
require 'shellwords'
require 'facter'
require 'rexec/task'

module Teapot
	module Commands
		module Helpers
			def run_executable(path, environment)
				environment = environment.flatten
		
				executable = environment[:install_prefix] + path
		
				Commands.run(executable)
			end
		end
		
		def self.processor_count
			# Get the number of virtual/physical processors
			count = Facter.processorcount.to_i rescue 1
			
			# Make sure we always return at least 1:
			count < 1 ? 1 : count
		end
		
		class CommandError < StandardError
		end
		
		def self.split(arg)
			Shellwords.split(arg || "")
		end
		
		def self.run(*args, &block)
			options = Hash === args.last ? args.pop : {}
			options[:passthrough] ||= :all
			
			args = args.flatten.collect &:to_s
			
			puts args.join(' ').color(:blue) + " in #{options[:chdir] || Dir.getwd}"
			
			task = RExec::Task.open(args, options, &block)
			
			if task.wait == 0
				true
			else
				raise CommandError.new("Non-zero exit status: #{args.join(' ')}!")
			end
		end
		
		def self.run!(*args, &block)
			run(*args, &block)
		rescue CommandError
			false
		end
		
		def wait
			# No parallel execution supported by default.
		end
		
		def self.make(*args)
			run("make", *args, "-j", processor_count)
		end
		
		def self.make_install
			make("install")
		end
		
		class Pool
			def initialize(options = {})
				@commands = []
				@limit = options[:limit] || Commands.processor_count
				
				@running = Set.new
			end
			
			def run(*args)
				args = args.flatten.collect &:to_s
				
				@commands << args
				
				schedule!
			end
			
			def schedule!
				while @running.size < @limit and @commands.size > 0
					command = @commands.shift
					
					puts command.join(' ').color(:blue)
					
					pid = Process.fork do
						exec(*command)
						
						exit!(0)
					end
					
					@running << pid
				end
			end
			
			def wait
				while @running.size > 0
					pid = Process.wait(0)
					@running.delete(pid)
					
					schedule!
				end
			end
		end
		
		def self.pipeline(parallel = false)
			if parallel == false
				# Non-parallel execution pipeline
				Commands
			else
				# Pool based parallel execution pipeline
				Pool.new(parallel == true ? {} : parallel)
			end
		end
	end
end
