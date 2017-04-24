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
require_relative 'dependency'
require_relative 'definition'

require 'build/environment'
require 'build/rulebook'

module Teapot
	class BuildError < StandardError
	end
	
	class Target < Definition
		include Dependency
		
		def initialize(context, package, name)
			super context, package, name
			
			@build = nil
			
			@rulebook = Build::Rulebook.new
		end
		
		attr :rulebook
		
		def freeze
			@build.freeze
			@rulebook.freeze
			
			super
		end
		
		# Given a specific configuration, generate the build environment based on this target and it's provision chain.
		def environment(configuration, chain)
			chain = chain.partial(self.targets)
			
			environments = []
			
			# Calculate the dependency chain's ordered environments:
			environments += chain.provisions.collect do |provision|
				Build::Environment.new(&provision.value)
			end
			
			# Per-configuration package package environment:
			environments << @package.options[:environment]
			
			# Merge all the environments together:
			environment = Build::Environment.combine(*environments)
			
			environment.merge do
				default platforms_path configuration.platforms_path
			end
		end
		
		# TODO Remove legacy method name.
		alias environment_for_configuration environment
		
		def build(&block)
			if block_given?
				@build = block
			end
			
			return @build
		end
	end
end
