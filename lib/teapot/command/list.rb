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

require 'samovar'

module Teapot
	module Command
		class List < Samovar::Command
			self.description = "List provisions and dependencies of the specified package."
			
			many :packages, "Limit the listing to only these packages, or all packages if none specified."
			
			def only
				if @packages.any?
					Set.new(@packages)
				end
			end
			
			def call(parent)
				context = parent.context
				
				logger = parent.logger
				
				context.configuration.packages.each do |package|
					# The root package is the local package for this context:
					next unless only == nil or only.include?(package.name)
					
					logger.info "Package #{package.name} (from #{package.path}):".bright
				
					begin
						script = context.load(package)
						definitions = script.defined
					
						definitions.each do |definition|
							logger.info "\t#{definition}"
					
							definition.description.each_line do |line|
								logger.info "\t\t#{line.chomp}".color(:cyan)
							end if definition.description
					
							case definition
							when Project
								logger.info "\t\t- Summary: #{definition.summary}" if definition.summary
								logger.info "\t\t- License: #{definition.license}" if definition.license
								logger.info "\t\t- Website: #{definition.website}" if definition.website
								logger.info "\t\t- Version: #{definition.version}" if definition.version
								
								definition.authors.each do |author|
									contact_text = [author.email, author.website].compact.collect{|text|" <#{text}>"}.join
									logger.info "\t\t- Author: #{author.name}" + contact_text
								end
							when Target
								definition.dependencies.each do |dependency|
									logger.info "\t\t- #{dependency}".color(:red)
								end
				
								definition.provisions.each do |name, provision|
									logger.info "\t\t- #{provision}".color(:green)
								end
							when Configuration
								definition.packages.each do |package|
									logger.info "\t\t- #{package}".color(:green)
								end
							
								definition.imports.select(&:explicit).each do |import|
									logger.info "\t\t- import #{import.name}".color(:red)
								end
							end
						end
					rescue NonexistantTeapotError => error
						logger.info "\t#{error.message}".color(:red)
					rescue IncompatibleTeapotError => error
						logger.info "\t#{error.message}".color(:red)
					end
				end
			end
		end
	end
end
