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
	class Environment
		Default = Struct.new(:value)
		Replace = Struct.new(:value)
		
		class Define
			def initialize(klass, block)
				@klass = klass
				@block = block
			end
			
			attr :klass
			attr :block
		end
		
		class Constructor
			def initialize(environment)
				@environment = environment
			end
	
			def method_missing(name, value = nil, &block)
				if block_given?
					@environment[name] = block
				else
					@environment[name] = value
				end
		
				name
			end
	
			def [] key
				@environment[key]
			end
	
			def default(name)
				@environment[name] = Default.new(@environment[name])
				
				return name
			end
			
			def replace(name)
				@environment[name] = Replace.new(@environment[name])
				
				return name
			end
			
			def append(name)
				@environment[name] = Array(@environment[name])
				
				return name
			end
			
			def define(name, klass, &block)
				@environment[name] = Define.new(klass, &block)
				
				return name
			end
		end
		
		def self.combine(*environments)
			# Flatten the list of environments:
			environments = environments.collect do |environment|
				if Environment === environment
					environment.to_a
				else
					environment
				end
			end.flatten
			
			# Resequence based on order:
			first = Environment.new(nil, environments.shift)
			top = first
			
			environments.each do |tail|
				top = Environment.new(top, tail)
			end
			
			return top
		end
		
		def merge(&block)
			self.class.combine(
				self,
				self.class.new(&block)
			)
		end
		
		# Convert the hierarchy of environments to an array where the parent comes before the child.
		def to_a
			flat = []
			
			flatten_to_array(flat)
			
			return flat
		end
		
		protected
		
		def flatten_to_array(array)
			if @parent
				@parent.flatten_to_array(array)
			end
			
			array << self
		end
	end
end
