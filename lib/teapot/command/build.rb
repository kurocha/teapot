# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../controller/build'

module Teapot
	module Command
		class Build < Samovar::Command
			self.description = "Build the specified target."
			
			options do
				option '-j/-l/--limit <n>', "Limit the build to <n> concurrent processes."
				option '--only', "Only compile direct dependencies."
				option '-c/--continuous', "Run the build graph continually (experimental)."
			end
			
			many :targets, "Build these targets, or use them to help the dependency resolution process."
			split :argv, "Arguments passed to child process(es) of build if any."
			
			def invoke(parent)
				# TODO: This is a bit of a hack, figure out a way to pass it directly through to build subsystem.
				ARGV.replace(@argv) if @argv
				
				parent.controller.build(@targets)
			end
		end
	end
end
