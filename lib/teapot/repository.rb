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

require 'teapot/commands'

module Teapot
	module Git
		class Repository
			def initialize(root, options = {})
				@root = root
				@options = options
			end

			def init!
				run!("init", @root)
			end

			def clone!(remote_url, branch = nil, commit = nil)
				branch_args = branch ? ["--branch", branch] : []

				@root.mkpath

				run!("clone", remote_url, @root, *branch_args)

				if commit
					run("reset", "--hard", commit)
				end

				run("submodule", "update", "--init", "--recursive")
			rescue
				#@root.rmtree

				raise
			end

			def update(branch, commit = nil)
				run("fetch", "origin")
				run("checkout", branch)

				# Pull any changes, if you might get the error from above:
				# Your branch is behind 'origin/0.1' by 1 commit, and can be fast-forwarded.
				run("pull")

				# Checkout the specific version if it was given:
				if commit
					run("reset", "--hard", commit)
				end

				run("submodule", "update", "--init", "--recursive")
			end

			def add(files)
				if files == :all
					run("add", "--all")
				else
					run("add", *files)
				end
			end

			private

			def run(*args)
				Commands.run("git", *args, :chdir => @root)
			end

			def run!(*args)
				Commands.run("git", *args)
			end
		end
	end

	module Repository
		def self.new(*args)
			Git::Repository.new(*args)
		end
	end
end
