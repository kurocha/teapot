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
require 'console/terminal'

require_relative 'selection'

module Teapot
	module Command
		class List < Selection
			self.description = "List provisions and dependencies of the specified package."
			
			def terminal(output = $stdout)
				Console::Terminal.for(output).tap do |terminal|
					terminal[:definition] = terminal.style(nil, nil, :bright)
					terminal[:dependency] = terminal.style(:blue)
					terminal[:provision] = terminal.style(:green)
					terminal[:package] = terminal.style(:yellow)
					terminal[:import] = terminal.style(:cyan)
					terminal[:error] = terminal.style(:red)
				end
			end
			
			def process(selection)
				context = selection.context
				terminal = self.terminal
				
				selection.resolved.each do |package|
					terminal.puts "Package #{package.name} (from #{package.path}):"
					
					begin
						script = context.load(package)
						definitions = script.defined
						
						definitions.each do |definition|
							terminal.puts "\t#{definition}", style: :definition
							
							definition.description.each_line do |line|
								terminal.puts "\t\t#{line.chomp}", style: :description
							end if definition.description
							
							case definition
							when Project
								terminal.puts "\t\t- Summary: #{definition.summary}" if definition.summary
								terminal.puts "\t\t- License: #{definition.license}" if definition.license
								terminal.puts "\t\t- Website: #{definition.website}" if definition.website
								terminal.puts "\t\t- Version: #{definition.version}" if definition.version
								
								definition.authors.each do |author|
									contact_text = [author.email, author.website].compact.collect{|text| " <#{text}>"}.join
									terminal.puts "\t\t- Author: #{author.name}" + contact_text
								end
							when Target
								definition.dependencies.each do |dependency|
									terminal.puts "\t\t- #{dependency}", style: :dependency
								end
								
								definition.provisions.each do |name, provision|
									terminal.puts "\t\t- #{provision}", style: :provision
								end
							when Configuration
								definition.packages.each do |package|
									terminal.puts "\t\t- #{package}", style: :package
								end
								
								definition.imports.select(&:explicit).each do |import|
									terminal.puts "\t\t- import #{import.name}", style: :import
								end
							end
						end
					rescue MissingTeapotError => error
						terminal.puts "\t#{error.message}", style: :error
					rescue IncompatibleTeapotError => error
						terminal.puts "\t#{error.message}", style: :error
					end
				end
			end
		end
	end
end
