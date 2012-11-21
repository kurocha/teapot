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

require 'rexec'
require 'rainbow'
require 'shellwords'

module Teapot
	class Environment
		module System
			def self.convert_to_shell(values)
				Hash[values.each{|key, value| [
					key.to_s.upcase,
					Shellwords.join(Array(value))
				]}]
			end
			
			def self.dump(environment, io = STDOUT)
				environment.to_hash.each do |key, value|
					io.puts "#{key}:".rjust(20).color(:magenta) + " #{value.inspect}"
				end
			end
		end
		
		# Construct an environment from a given system environment:
		def self.system_environment(env = ENV)
			self.new(Hash[env.to_hash.collect{|key, value| [key.downcase.to_sym, value]}])
		end
		
		# Apply the environment to the current process temporarily:
		def use(options = {}, &block)
			# Flatten the environment to a hash:
			values = flatten
			
			# Convert the hash to suit typical shell specific arguments:
			system_environment = System::convert_to_shell(environment)
			
			# Show the environment to the user:
			System::dump(values)
			
			Dir.chdir(options[:in] || ".") do
				RExec.env(system_environment) do
					block.call(values)
				end
			end
		end
	end
end
