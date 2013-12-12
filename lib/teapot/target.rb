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
require 'teapot/dependency'
require 'teapot/definition'

require 'teapot/rulebook'

module Teapot
	class BuildError < StandardError
	end
	
	class Target < Definition
		include Dependency
		
		def initialize(context, package, name)
			super context, package, name
			
			@build = nil
			
			@rulebook = Rulebook.new
		end
		
		attr :rulebook
		
		def provision_chain(configuration)
			# Reduce the number of keystrokes for good health:
			context = configuration.context
			
			chain = Dependency::chain(context.selection, dependencies, context.targets.values)
		end
		
		def environment_for_configuration(configuration)
			chain = provision_chain(configuration)
			
			environments = []
			
			# Calculate the dependency chain's ordered environments:
			environments += chain.provisions.collect do |provision|
				Environment.new(&provision.value)
			end
			
			# Per-configuration package package environment:
			environments << @package.options[:environment]
			
			# Merge all the environments together:
			environment = Environment.combine(*environments)
				
			environment.merge do
				default platforms_path configuration.platforms_path
				default build_prefix {platforms_path + "cache/#{platform_name}-#{variant}"}
				default install_prefix {platforms_path + "#{platform_name}-#{variant}"}
			
				append buildflags {"-I#{install_prefix + "include"}"}
				append linkflags {"-L#{install_prefix + "lib"}"}
			end
		end
		
		def build(&block)
			if block_given?
				@build = block
			end
			
			return @build
		end
	end
end
