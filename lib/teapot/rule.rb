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
require 'set'

require 'yaml/store'

require 'teapot/context'
require 'teapot/environment'
require 'teapot/commands'

require 'teapot/definition'

module Teapot
	class Rule < Definition
		def initialize(context, package, name)
			super context, package, name
			
			process_name, @type = name.split('.', 2)
			@process = process_name.gsub('-', '_').to_sym
			
			@apply = nil
		end
		
		attr :process
		attr :types
		
		def apply(&block)
			@apply = Proc.new(&block)
		end

		def apply!(*args)
			@apply[*args]
		end
		
		def to_s
			"<#{self.class.name} #{@name.dump}>"
		end
	end
	
	class Rulebook
		def initialize
			@rules = {}
			@processes = {}
		end

		def << rule
			@rules[rule.name] = rule
			
			# A cache for fast process/file-type lookup:
			processes = @processes[rule.process] ||= {}
			processes[rule.type] = rule
		end

		def [] name
			@rules[name]
		end
		
		def apply(process_name, *args)
			@processes[process_name].apply!(*args)
		end
		
		def method_missing(name, *args)
			if @processes.include? name
				apply(name, *args)
			else
				super
			end
		end
		
		def respond_to?(name)
			@processes.include?(name) || super
		end
	end
end
