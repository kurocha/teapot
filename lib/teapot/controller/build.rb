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

require 'teapot/controller'

module Teapot
	class Controller
		def build(package_names)
			context, configuration = load_teapot
		
			configuration.load_all
		
			context.select(package_names)
		
			chain = Dependency::chain(context.selection, context.dependencies, context.targets.values)
		
			if chain.unresolved.size > 0
				log "Unresolved dependencies:"
		
				chain.unresolved.each do |(name, parent)|
					log "#{parent} depends on #{name.inspect}".color(:red)
				
					conflicts = chain.conflicts[name]
				
					if conflicts
						conflicts.each do |conflict|
							log " - provided by #{conflict.inspect}".color(:red)
						end
					end
				end
			
				abort "Cannot continue build due to unresolved dependencies!".color(:red)
			end
	
			log "Resolved: #{chain.resolved.inspect}".color(:magenta)
	
			ordered = chain.ordered
		
			if @options[:only]
				ordered = context.direct_targets(ordered)
			end
		
			ordered.each do |(target, dependency)|
				log "Building #{target.name} for dependency #{dependency}...".color(:cyan)
		
				if target.respond_to?(:build!) and !@options[:dry]
					target.build!(configuration)
				end
			end
	
			log "Completed build successfully.".color(:green)
		end
	end
end
