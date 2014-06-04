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

require 'teapot/configuration'
require 'teapot/version'

require 'uri'
require 'rainbow'
require 'rainbow/ext/string'
require 'fileutils'

module Teapot
	class Controller
		MAXIMUM_FETCH_DEPTH = 20
		
		def initialize(root, options)
			@root = Pathname(root)
			@options = options
			
			@log_output = @options.fetch(:log, $stdout)
			
			@options[:maximum_fetch_depth] ||= MAXIMUM_FETCH_DEPTH
		end
		
		def log(*args)
			@log_output.puts *args
		end
		
		def context
			@context ||= Context.new(@root,
				:configuration => @options[:configuration]
			)
		end
	end
end
