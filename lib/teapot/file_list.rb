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

require 'pathname'
require 'fileutils'

module Teapot
	class FileList
		include Enumerable
		
		def self.[] (root, pattern, prefix = nil)
			self.new(root, pattern, prefix)
		end
		
		def initialize(root, pattern, prefix = nil)
			@root = root
			@pattern = pattern
			@prefix = Pathname.new(prefix || ".")
		end

		attr :root
		attr :pattern
		attr :prefix

		def each(&block)
			Pathname.glob(@root + @pattern).each &block
		end
		
		def copy(destination)
			self.each do |path|
				# Compute the destination path, which is formed using the relative path:
				relative_path = path.relative_path_from(@root)
				destination_path = destination + @prefix + relative_path
				
				if path.directory?
					# Make a directory at the destination:
					destination_path.mkpath
				else
					# Make the path if it doesn't already exist:
					destination_path.dirname.mkpath
				
					# Copy the file to the destination:
					FileUtils.cp(path, destination_path, :preserve => true)
				end
			end
		end
	end
end
