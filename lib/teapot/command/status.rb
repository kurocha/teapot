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
require 'rugged'

module Teapot
	module Command
		class Status < Samovar::Command
			self.description = "List the git status of the specified package(s)."
			
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
					
					repository = Rugged::Repository.new(package.path.to_s)
					
					changes = {}
					repository.status do |file, status|
						unless status == [:ignored]
							changes[file] = status
						end
					end
					
					next if changes.empty?
					
					logger.info "Package #{package.name} (from #{package.path}):".bright
					
					changes.each do |file, status|
						if status == [:worktree_new]
							logger.info "\t#{file}".color(:blue)
						elsif status == [:worktree_modified]
							logger.info "\t#{file}".color(:orange)
						elsif status == [:worktree_deleted]
							logger.info "\t#{file}".color(:red)
						else
							logger.info "\t#{file} #{status.inspect}"
						end
					end
				end
			end
		end
	end
end
