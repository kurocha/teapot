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

require_relative 'selection'
require 'rugged'
require 'console/terminal'

module Teapot
	module Command
		class Status < Selection
			self.description = "List the git status of the specified package(s)."
			
			def terminal(output = $stdout)
				Console::Terminal.for(output).tap do |terminal|
					terminal[:worktree_new] = terminal.style(:green)
					terminal[:worktree_modified] = terminal.style(:yellow)
					terminal[:worktree_deleted] = terminal.style(:red)
				end
			end
			
			def repository_for(package)
				Rugged::Repository.new(package.path.to_s)
			rescue Rugged::RepositoryError
				# In some cases, a repository might not exist yet, so just skip the package.
				nil
			end
			
			def process(selection)
				context = selection.context
				terminal = self.terminal
				
				selection.resolved.each do |package|
					if repository = repository_for(package)
						changes = {}
						repository.status do |file, status|
							unless status == [:ignored]
								changes[file] = status
							end
						end
						
						next if changes.empty?
						
						terminal.puts "Package #{package.name} (from #{package.path}):"
						
						changes.each do |file, statuses|
							terminal.puts "\t#{file} (#{statuses})", style: statuses.last
						end
					end
				end
			end
		end
	end
end
