# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
require 'build/name'

require_relative 'fetch'
require 'rugged'

require 'build/uri'

module Teapot
	module Command
		class Clone < Samovar::Command
			self.description = "Clone a remote repository and fetch all dependencies."
			
			one :source, "The source repository to clone."
			
			def invoke(parent)
				raise ArgumentError, "source is required" unless @source
				
				logger = parent.logger
				
				name = File.basename(::Build::URI[@source].path, ".git")
				
				nested = parent['--root', parent.options[:root] || name]
				root = nested.root
				
				if root.exist?
					raise ArgumentError.new("#{root} already exists!")
				end
				
				logger.info "Cloning #{@source} to #{root}...".color(:cyan)
				_repository = Rugged::Repository.clone_at(@source, root.to_s, credentials: self.method(:credentials))
				
				# Fetch the initial packages:
				Fetch[].invoke(nested)
			end
			
			def credentials(url, username, types)
				# We should prompt for username/password if required...
				return Rugged::Credentials::SshKeyFromAgent.new(username: username)
			end
		end
	end
end
