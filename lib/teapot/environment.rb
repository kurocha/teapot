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
require 'yaml'

require 'teapot/package'
require 'teapot/platform'

module Teapot
	class Environment
		Default = Struct.new(:value)
		
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
			end
		end
		
		class Evaluator
			def initialize(environment)
				@environment = environment
			end
			
			def method_missing(name)
				object_value(@environment[name])
			end
			
			private
			
			# Compute the literal object value for a given key:
			def object_value(value)
				case value
				when Array
					value.collect{|item| object_value(item)}
				when Symbol
					object_value(@values[value])
				when Proc
					object_value(instance_eval(&value))
				when Default
					object_value(value.value)
				else
					value
				end
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
		
		def initialize(parent = nil, values = nil, &block)
			@values = (values || {}).to_hash
			@parent = parent
			
			@evaluator = Evaluator.new(self)
			
			if block_given?
				construct(&block)
			end
		end
		
		def construct(&block)
			Constructor.new(self).instance_eval(&block)
		end
		
		def dup
			self.class.new(@values)
		end
		
		attr :values
		attr :parent
		
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
		
		def flatten
			hash = {}
			
			flatten_to_hash(hash)
			
			Environment.new(nil, hash)
		end
		
		def to_string_hash
			Hash[@values.map{|key, value| [key.to_s.upcase, string_value(value)]}]
		end
		
		def use(&block)
			system_environment = flatten.to_string_hash
			
			puts YAML::dump(system_environment).color(:magenta)
			
			RExec.env(system_environment) do
				@evaluator.instance_eval(&block)
			end
		end
		
		def to_s
			"<#{self.class} #{self.values}>"
		end
		
		def to_a
			flat = []
			
			flatten_to_array(flat)
			
			return flat
		end
		
		protected
		
		def flatten_to_array(array)
			array << self
			
			if @parent
				@parent.flatten_to_array(array)
			end
		end
		
		def flatten_to_hash(hash)
			if @parent
				@parent.flatten_to_hash(hash)
			end
			
			@values.each do |key, value|
				previous = hash[key]

				if Array === previous
					hash[key] = previous + Array(value)
				elsif Default == previous
					hash[key] ||= previous
				else
					hash[key] = value
				end
			end
		end
		
		# Compute the literal string value for a given key:
		def string_value(value)
			case value
			when Array
				value.collect{|item| string_value(item)}.join(' ')
			when Symbol
				string_value(@values[value])
			when Proc
				string_value(@evaluator.instance_eval(&value))
			when Default
				string_value(value.value)
			else
				value.to_s
			end
		end
		
		def lookup(name)
			if @values.include? name
				self
			elsif @parent
				@parent.lookup(name)
			end
		end
	end
end
