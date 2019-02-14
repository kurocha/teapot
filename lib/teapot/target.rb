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
require 'build/dependency'
require_relative 'definition'

require 'build/environment'
require 'build/rulebook'

module Teapot
	class BuildError < StandardError
	end
	
	class Target < Definition
		include Build::Dependency
		
		def initialize(*)
			super
			
			@build = nil
		end
		
		def freeze
			return self if frozen?
			
			@build.freeze
			
			super
		end
		
		def build(&block)
			if block_given?
				@build = block
			end
			
			return @build
		end
		
		def update_environments!
			return unless @build
			
			self.provisions.each do |key, provision|
				build = @build
				original = provision.value
				
				wrapper = proc do |*arguments|
					self.instance_exec(*arguments, &original) if original
					self.instance_exec(*arguments, &build) if build
				end
				
				provision.value = wrapper
			end
			
			@build = nil
		end
	end
end
