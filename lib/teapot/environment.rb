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

require 'pathname'
require 'rainbow'

require 'rexec'

require 'teapot/package'
require 'teapot/platform'

module Teapot
	class Environment
		def initialize(values = {})
			@values = values
		end
		
		attr :values
		
		def method_missing(name, *args)
			if name.to_s.match(/^(.*?)(\=)?$/)
				if $2
					return @values[$1.to_sym] = args[0]
				else
					return @values[$1.to_sym]
				end
			else
				super(name, *args)
			end
		end
		
		def [] (key)
			@values[key]
		end
		
		def []= (key, value)
			@values[key] = value
		end
		
		def to_hash
			@values
		end
		
		def merge(config)
			environment = Environment.new(values)
			environment.merge!(config)
		end
		
		def merge!(config)
			if config
				@values.merge!(config.to_hash) do |key, old_value, new_value|
					if Array === old_value || Array === new_value
						Array(old_value) + Array(new_value)
					else
						new_value
					end
				end
			end
			
			@values.merge!(config.to_hash) if config
			
			return self
		end
		
		def environment_variables
			Hash[@values.map{|key, value| [key.to_s.upcase, Array(value).join(' ')]}]
		end
		
		def use(&block)
			RExec.env(environment_variables, &block)
		end
	end
end
