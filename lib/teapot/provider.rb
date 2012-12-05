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

require 'set'

require 'teapot/environment'

module Teapot
	module Provider
		class Controller
			def initialize
				@provides = {}
				@depends = Set.new
			end
		
			attr :provides
			attr :depends
		end
		
		def provider
			@provider ||= Controller.new
		end
		
		def provides? name
			provider.provides.key? name
		end
		
		def environment_for name
			configuration = provider.provides[name]
			
			if configuration
				Environment.new(&configuration)
			end
		end
		
		def provides(name, &block)
			provider.provides[name] = Proc.new &block
		end
		
		def depends(name)
			provider.depends << name
		end
		
		def depends? name
			provider.depends.include? name
		end
		
		def dependencies
			provider.depends
		end
		
		def self.dependency_chain(dependencies, providers)
			resolved = Set.new
			ordered = []
			unresolved = []

			expand = lambda do |dependency, parent|
				provider = providers.find{|provider| provider.provides? dependency}

				unless provider
					unresolved << [dependency, parent]
				else
					provider.dependencies.each do |dependency|
						expand.call(dependency, provider)
					end

					unless resolved.include? dependency
						ordered << [provider, dependency]
						resolved << dependency
					end
				end
			end

			dependencies.each do |dependency|
				expand.call(dependency, nil)
			end

			return {:ordered => ordered, :resolved => resolved, :unresolved => unresolved}
		end
		
		def self.environment_for(dependencies, providers)
			environments = dependencies.collect do |name|
				provider = providers.find{|provider| provider.provides? name}
				
				if provider
					provider.environment_for(name)
				end
			end.compact
			
			return Environment.combine(*environments)
		end
	end
end
