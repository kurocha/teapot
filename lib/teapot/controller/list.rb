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
		def list(only = nil)
			# Should this somehow consider context.root_package?
			context.configuration.packages.each do |package|
				# The root package is the local package for this context:
				next unless only == nil or only.include?(package.name)
				
				log "Package #{package.name} (from #{package.path}):".bright
			
				begin
					definitions = context.load(package)
				
					definitions.each do |definition|
						log "\t#{definition}"
				
						definition.description.each_line do |line|
							log "\t\t#{line.chomp}".color(:cyan)
						end if definition.description
				
						case definition
						when Project
							log "\t\t- Summary: #{definition.summary}" if definition.summary
							log "\t\t- License: #{definition.license}" if definition.license
							log "\t\t- Website: #{definition.website}" if definition.website
							log "\t\t- Version: #{definition.version}" if definition.version
							
							definition.authors.each do |author|
								contact_text = [author.email, author.website].compact.collect{|text|" <#{text}>"}.join
								log "\t\t- Author: #{author.name}" + contact_text
							end
						when Target
							definition.dependencies.each do |name|
								log "\t\t- depends on #{name.inspect}".color(:red)
							end
			
							definition.provisions.each do |(name, provision)|
								if Dependency::Alias === provision
									log "\t\t- provides #{name.inspect} => #{provision.dependencies.inspect}".color(:green)
								else
									log "\t\t- provides #{name.inspect}".color(:green)
								end
							end
						when Configuration
							definition.materialize
						
							definition.packages.each do |package|
								if package.local?
									log "\t\t- links #{package.name} from #{package.options[:local]}".color(:green)
								elsif package.external?
									log "\t\t- clones #{package.name} from #{package.external_url(context.root)}".color(:green)
								else
									log "\t\t- references #{package.name} from #{package.path}".color(:green)
								end
							end
						
							definition.imports.select(&:explicit).each do |import|
								log "\t\t- unmaterialised import #{import.name}".color(:red)
							end
						end
					end
				rescue NonexistantTeapotError => error
					log "\t#{error.message}".color(:red)
				rescue IncompatibleTeapotError => error
					log "\t#{error.message}".color(:red)
				end
			end
		end
	end
end
