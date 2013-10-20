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

module Teapot
	class Definition
		def initialize(context, package, name)
			@context = context
			@package = package
			
			@name = name
			
			@description = nil
		end

		# The context in which the definition was loaded:
		attr :context
		
		# The package in which the definition was specified:
		attr :package
		
		# The name of the definition:
		attr :name
		
		# A textual description of the definition, possibly in markdown format:
		attr :description, true
		
		def description=(text)
			if text =~ /^(\t+)/
				text = text.gsub(/#{$1}/, '')
			end
			
			@description = text
		end
		
		# The path that the definition is relative to:
		def path
			@package.path
		end
		
		def to_s
			"<#{self.class.name} #{@name.dump}>"
		end
	end
end
