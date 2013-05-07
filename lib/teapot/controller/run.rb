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
		def run(dependency_names = [])
			configuration = context.configuration
			
			log "Running configuration #{configuration[:run].inspect}"
			
			chain, ordered = build(configuration[:run] + dependency_names)
			
			ordered.each do |(target, dependency)|
				if target.respond_to?(:run!) and !@options[:dry]
					log "Running #{target.name} for dependency #{dependency}...".color(:cyan)
					
					target.run!(configuration)
				end
			end
		end
		
		def invoke(environment, command)
			binary_path = environment[:install_prefix]
			
			Dir.chdir(binary_path.to_s) do
				Commands.run(*command)
			end
		end
	end
end
