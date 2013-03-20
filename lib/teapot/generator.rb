# Copyright, 2013, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'teapot/definition'

module Teapot
	class Generator < Definition
		def initialize(context, package, name)
			super context, package, name
			
			@generate = nil
		end

		def generate(&block)
			@generate = Proc.new(&block)
		end

		def generate!(*args)
			@generate[*args]
		end
		
		def substitute(text, substitutions)
			return text unless substitutions
			
			# Use positive look behind so that the pattern is just the substitution key:
			pattern = Regexp.new('(?<=\$)' + substitutions.keys.map{|x| Regexp.escape(x)}.join('|'))
			
			text.gsub(pattern) {|key| substitutions[key]}
		end
		
		def append(source, destination, substitutions = nil)
			source_path = Pathname(path) + source
			destination_path = Pathname(context.config.root) + destination
			
			File.open(destination_path, "a") do |file|
				text = File.read(source_path)
				
				file.write substitute(text, substitutions)
			end
		end
	end
end
