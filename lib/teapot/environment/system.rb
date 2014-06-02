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

require 'rexec/environment'

require 'rainbow'
require 'rainbow/ext/string'

module Teapot
	class Environment
		module System
			def self.shell_escape(value)
				case value
				when Array
					value.flatten.collect{|argument| shell_escape(argument)}.join(' ')
				else
					# Ensure that any whitespace has been escaped:
					value.to_s.gsub(/ /, '\ ')
				end
			end
			
			def self.convert_to_shell(environment)
				Hash[environment.values.map{|key, value| [
					key.to_s.upcase,
					shell_escape(value)
				]}]
			end
			
			def self.dump(environment, io = STDOUT)
				environment.values.each do |key, value|
					io.puts "#{key}:".rjust(20).color(:magenta) + " #{value.inspect}"
				end
			end
		end
		
		# Construct an environment from a given system environment:
		def self.system_environment(env = ENV)
			self.new(Hash[env.map{|key, value| [key.downcase.to_sym, value]}])
		end
	end
end
