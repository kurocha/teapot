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

module Teapot
	# This is the basic environment data structure which is essentially a linked list of hashes. It is primarily used for organising build configurations across a wide range of different sub-systems, e.g. platform configuration, target configuration, local project configuration, etc. The majority of the actual functionality is exposed in the `environment/*.rb` files.
	class Environment
		def initialize(parent = nil, values = {}, &block)
			@values = (values || {}).to_hash
			@parent = parent
			
			if block_given?
				Constructor.new(self).instance_exec(&block)
			end
		end
		
		attr :values
		attr :parent
		
		def lookup(name)
			if @values.include? name
				self
			elsif @parent
				@parent.lookup(name)
			end
		end
		
		def [] (key)
			environment = lookup(key)
			
			environment ? environment.values[key] : nil
		end
		
		def []= (key, value)
			@values[key] = value
		end
		
		def to_hash
			@values
		end
		
		def to_s
			"<#{self.class} #{self.values}>"
		end
	end
end