# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
	# Very similar to a set but uses a specific callback (defaults to &:name) for object identity.
	class IdentitySet
		include Enumerable
		
		def initialize(contents = [])
			@table = {}
			
			contents.each do |object|
				add(object)
			end
		end
		
		def freeze
			@table.freeze
			
			super
		end
		
		def initialize_dup(other)
			@table = other.table.dup
		end
		
		def identity(object)
			object.name
		end
		
		attr :table
		
		def add(object)
			@table[identity(object)] = object
		end
		
		alias << add
		def remove(object)
			@table.delete(identity(object))
		end
		
		def include?(object)
			@table.include?(identity(object))
		end
		
		def each(&block)
			@table.each_value(&block)
		end
		
		def size
			@table.size
		end
		
		def empty?
			@table.empty?
		end
		
		def clear
			@table.clear
		end
		
		alias count size
		
		def [] key
			@table[key]
		end
		
		def to_s
			@table.to_s
		end
	end
end
