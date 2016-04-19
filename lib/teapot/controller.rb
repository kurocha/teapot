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

require_relative 'configuration'
require_relative 'version'

require 'uri'
require 'rainbow'
require 'rainbow/ext/string'
require 'fileutils'

require 'build/logger'

module Teapot
	class Controller
		def initialize(root, options)
			@root = Pathname(root)
			@options = options
			
			@log_output = @options.fetch(:log, $stdout)
			@logging = @options[:logging] 
		end
		
		def verbose?
			@logging == :verbose
		end
		
		def quiet?
			@logging == :quiet
		end
		
		def logger
			@logger ||= Logger.new(@log_output).tap do |logger|
				logger.formatter = Build::CompactFormatter.new(verbose: verbose?)
				
				if verbose?
					logger.level = Logger::DEBUG
				elsif quiet?
					logger.level = Logger::WARN
				else
					logger.level = Logger::INFO
				end
			end
		end
		
		def log(*args)
			logger.info(*args)
		end
		
		def configuration
			@options[:configuration]
		end
		
		def context
			@context ||= Context.new(@root, configuration: configuration)
		end
		
		# Reload the current context, e.g. if it's been modified by a generator.
		def reload!
			@context = nil
		end
	end
end
