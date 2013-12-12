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
		def to_hash
			hash = {}
			
			# Flatten this chain of environments:
			flatten_to_hash(hash)
			
			# Evaluate all items to their respective object value:
			evaluator = Evaluator.new(hash)
			
			# Evaluate all the individual environment values so that they are flat:
			Hash[hash.map{|key, value| [key, evaluator.object_value(value)]}]
		end
		
		def flatten
			Environment.new(nil, self.to_hash)
		end
		
		def defined
			@values.select{|name,value| Define === value}
		end
		
		protected
		
		def flatten_to_hash(hash)
			if @parent
				@parent.flatten_to_hash(hash)
			end

			@values.each do |key, value|
				previous = hash[key]

				if Replace === value
					# Replace the parent value
					hash[key] = value
				elsif Array === previous
					# Merge with the parent value
					hash[key] = previous + Array(value)
				elsif Default === value
					# Update the parent value if not defined.
					hash[key] = previous || value
				else
					hash[key] = value
				end
			end
		end
	end
end
