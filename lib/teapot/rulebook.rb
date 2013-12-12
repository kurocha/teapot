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

require 'teapot/rule'

module Teapot
	class Rulebook
		def initialize
			@rules = {}
			@processes = {}
		end
		
		attr :rules
		
		def << rule
			@rules[rule.name] = rule
		
			# A cache for fast process/file-type lookup:
			processes = @processes[rule.process_name] ||= []
			processes << rule
		end

		def [] name
			@rules[name]
		end
		
		def with(superclass, state = {})
			task_class = Class.new(superclass)
			
			# Define methods for all processes, e.g. task_class#compile
			@processes.each do |key, rules|
				# Define general rules, which use rule applicability for disambiguation:
				task_class.send(:define_method, key) do |arguments, &block|
					rule = rules.find{|rule| rule.applicable? arguments }
					
					if rule
						update(rule, arguments, &block)
					else
						raise NoApplicableRule.new(arguments)
					end
				end
			end
			
			# Define methods for all rules, e.g. task_class#compile_cpp
			@rules.each do |key, rule|
				task_class.send(:define_method, rule.full_name) do |arguments, &block|
					update(rule, arguments, &block)
				end
			end
			
			state.each do |key, value|
				task_class.send(:define_method, key) do
					value
				end
			end
			
			return task_class
		end
		
		def self.for(environment)
			rulebook = self.new
			
			environment.defined.each do |name, define|
				object = define.klass.new(*name.split('.', 2))
				
				object.instance_eval(&define.block)
				
				rulebook << object
			end
			
			return rulebook
		end
	end
end
