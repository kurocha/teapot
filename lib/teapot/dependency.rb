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

module Teapot
	module Dependency
		class UnresolvedDependencyError < StandardError
			def initialize(chain)
				super "Unresolved dependency chain!"
				
				@chain = chain
			end
			
			attr :chain
		end
		
		Provision = Struct.new(:value)
		Alias = Struct.new(:dependencies)
		Resolution = Struct.new(:provider, :name)
		
		def priority= value
			@priority = value
		end
		
		def priority
			@priority || 0
		end
		
		def provides?(name)
			provisions.key? name
		end
		
		def provides(name_or_aliases, &block)
			if String === name_or_aliases || Symbol === name_or_aliases
				name = name_or_aliases
				
				provisions[name] = Provision.new(block)
			else
				aliases = name_or_aliases
				
				aliases.each do |name, dependencies|
					provisions[name] = Alias.new(Array(dependencies))
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
			def initialize(selection, dependencies, providers, options = {})
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
				
				@options = options
				
				@dependencies.each do |dependency|
					expand(dependency, "<top>")
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
			
			def ignore_priority?
				@options[:ignore_priority]
			end
			
			def filter_by_priority(viable_providers)
				# Sort from highest priority to lowest priority:
				viable_providers = viable_providers.sort{|a,b| b.priority <=> a.priority}
				
				# The first item has the highest priority:
				highest_priority = viable_providers.first.priority
				
				# We compute all providers with the same highest priority (may be zero):
				return viable_providers.take_while{|provider| provider.priority == highest_priority}
			end
			
			def filter_by_selection(viable_providers)
				return viable_providers.select{|provider| @selection.include? provider.name}
			end
			
			def find_provider(dependency, parent)
				# Mostly, only one package will satisfy the dependency...
				viable_providers = @providers.select{|provider| provider.provides? dependency}

				# puts "** Found #{viable_providers.collect(&:name).join(', ')} viable providers.".color(:magenta)

				if viable_providers.size > 1
					# ... however in some cases (typically where aliases are being used) an explicit selection must be made for the build to work correctly.
					explicit_providers = filter_by_selection(viable_providers)
					
					# puts "** Filtering to #{explicit_providers.collect(&:name).join(', ')} explicit providers.".color(:magenta)
					
					if explicit_providers.size != 1 and !ignore_priority?
						# If we were unable to select a single package, we may use the priority to limit the number of possible options:
						explicit_providers = viable_providers if explicit_providers.empty?
						
						explicit_providers = filter_by_priority(explicit_providers)
					end
					
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
				# puts "** Expanding #{dependency} from #{parent}".color(:magenta)
				
				if @resolved.include? dependency
					# puts "** Already resolved dependency!".color(:magenta)
					
					return
				end
				
				provider = find_provider(dependency, parent)

				if provider == nil
					# puts "** Couldn't find provider -> unresolved".color(:magenta)
					@unresolved << [dependency, parent]
					return nil
				end
				
				provision = provider.provisions[dependency]
				
				# We will now satisfy this dependency by satisfying any dependent dependencies, but we no longer need to revisit this one.
				@resolved << dependency

				# If the provision was an Alias, make sure to resolve the alias first:
				if Alias === provision
					# puts "** Resolving alias #{provision}".color(:magenta)

					provision.dependencies.each do |dependency|
						expand(dependency, provider)
					end
				end

				unless @resolved.include?(provider)
					# We are now satisfying the provider by expanding all its own dependencies:
					@resolved << provider

					# Make sure we satisfy the provider's dependencies first:
					provider.dependencies.each do |dependency|
						expand(dependency, provider)
					end

					# puts "** Appending #{dependency} -> ordered".color(:magenta)
					
					# Add the provider to the ordered list.
					@ordered << Resolution.new(provider, dependency)
				end
				
				# This goes here because we want to ensure 1/ that if 
				unless provision == nil or Alias === provision
					# puts "** Appending #{dependency} -> provisions".color(:magenta)
					
					# Add the provision to the set of required provisions.
					@provisions << provision
				end
				
				# For both @ordered and @provisions, we ensure that for [...xs..., x, ...], x is satisfied by ...xs....
			end
		end
		
		# An `UnresolvedDependencyError` will be thrown if there are any unresolved dependencies.
		def self.chain(selection, dependencies, providers)
			chain = Chain.new(selection, dependencies, providers)

			if chain.unresolved.size > 0
				raise UnresolvedDependencyError.new(chain)
			end

			return chain
		end
	end
end
