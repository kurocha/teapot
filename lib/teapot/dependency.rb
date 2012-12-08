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
	module Dependency
		Provision = Struct.new(:value)
		Alias = Struct.new(:dependencies)
		
		def provides?(name)
			provisions.key? name
		end
		
		def provides(name_or_aliases, &block)
			if String === name_or_aliases || Symbol === name_or_aliases
				name = name_or_aliases
				
				if block_given?
					provisions[name] = Provision.new(block)
				else
					provisions[name] = Provision.new(nil)
				end
			else
				aliases = name_or_aliases
				
				aliases.each do |(name, dependencies)|
					provisions[name] = Alias.new(Array dependencies)
				end
			end
		end
		
		def provisions
			@provisions ||= {}
		end
		
		def depends(name)
			dependencies << name
		end
		
		def depends?(name)
			dependencies.include? name
		end
		
		def dependencies
			@dependencies ||= Set.new
		end
		
		class Chain
			def initialize(selection, dependencies, providers)
				# Explicitly selected targets which will be used when resolving ambiguity:
				@selection = Set.new(selection)
				
				# The list of dependencies that needs to be satisfied:
				@dependencies = dependencies
				
				# The available providers which match up to required dependencies:
				@providers = providers
				
				@resolved = Set.new
				@ordered = []
				@provisions = []
				@unresolved = []
				@conflicts = {}
				
				@dependencies.each do |dependency|
					expand(dependency, nil)
				end
			end
			
			attr :selection
			attr :dependencies
			attr :providers
			
			attr :resolved
			attr :ordered
			attr :provisions
			attr :unresolved
			attr :conflicts
			
			private
			
			def find_provider(dependency, parent)
				# Mostly, only one package will satisfy the dependency...
				viable_providers = @providers.select{|provider| provider.provides? dependency}

				puts "** Found #{viable_providers.collect(&:name).join(', ')} viable providers.".color(:magenta)

				if viable_providers.size > 1
					# ... however in some cases (typically where aliases are being used) an explicit selection must be made for the build to work correctly.
					explicit_providers = viable_providers.select{|provider| @selection.include? provider.name}

					puts "** Filtering to #{explicit_providers.collect(&:name).join(', ')} explicit providers.".color(:magenta)

					if explicit_providers.size == 0
						# No provider was explicitly specified, thus we require explicit conflict resolution:
						@conflicts[dependency] = viable_providers
						return nil
					elsif explicit_providers.size == 1
						# The best outcome, a specific provider was named:
						return explicit_providers.first
					else
						# Multiple providers were explicitly mentioned that satisfy the dependency.
						@conflicts[dependency] = explicit_providers
						return nil
					end
				else
					return viable_providers.first
				end
			end
			
			def expand(dependency, parent)
				puts "** Expanding #{dependency} from #{parent}".color(:magenta)
				
				if @resolved.include? dependency
					puts "** Already resolved dependency!".color(:magenta)
					
					return
				end
				
				provider = find_provider(dependency, parent)

				if provider == nil
					puts "** Couldn't find provider -> unresolved".color(:magenta)
					@unresolved << [dependency, parent]
					return nil
				end
				
				provision = provider.provisions[dependency]
				
				# We will now satisfy this dependency by satisfying any dependent dependencies, but we no longer need to revisit this one.
				@resolved << dependency
				
				if Alias === provision
					puts "** Resolving alias #{provision}".color(:magenta)
					
					provision.dependencies.each do |dependency|
						expand(dependency, provider)
					end
				elsif provision != nil
					puts "** Appending #{dependency} -> provisions".color(:magenta)
					@provisions << provision
				end
				
				unless @resolved.include?(provider)
					# We are now satisfying the provider by expanding all its own dependencies:
					@resolved << provider
					
					provider.dependencies.each do |dependency|
						expand(dependency, provider)
					end
					
					puts "** Appending #{dependency} -> ordered".color(:magenta)
					@ordered << [provider, dependency]
				end
			end
		end
		
		def self.chain(selection, dependencies, providers)
			Chain.new(selection, dependencies, providers)
		end
	end
end
