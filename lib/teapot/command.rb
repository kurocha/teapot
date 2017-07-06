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

require_relative 'command/build'
require_relative 'command/clean'
require_relative 'command/create'
require_relative 'command/fetch'
require_relative 'command/list'
require_relative 'command/status'
require_relative 'command/visualize'

require_relative 'context'
require_relative 'configuration'
require_relative 'version'

require 'uri'
require 'rainbow'
require 'rainbow/ext/string'
require 'fileutils'

require 'build/logger'

module Teapot
	module Command
		def self.parse(*args)
			Top.parse(*args)
		end
		
		class Top < Samovar::Command
			self.description = "A decentralised package manager and build tool."
			
			options do
				option '-c/--configuration <name>', "Specify a specific build configuration.", default: ENV['TEAPOT_CONFIGURATION']
				option '--root <path>', "Work in the given root directory."
				option '--verbose | --quiet', "Verbosity of output for debugging.", key: :logging
				option '-h/--help', "Print out help information."
				option '-v/--version', "Print out the application version."
			end
			
			nested '<command>',
				'create' => Create,
				'fetch' => Fetch,
				'list' => List,
				'status' => Status,
				'build' => Build,
				'visualize' => Visualize,
				'clean' => Clean
			
			def root
				::Build::Files::Path.expand(@options[:root] || Dir.getwd)
			end
			
			def verbose?
				@logging == :verbose
			end
			
			def quiet?
				@logging == :quiet
			end
			
			def log_output
				@options.fetch(:log, $stderr)
			end
			
			def logger
				@logger ||= Logger.new(log_output).tap do |logger|
					logger.formatter = ::Build::CompactFormatter.new(verbose: verbose?)
					
					if verbose?
						logger.level = Logger::DEBUG
					elsif quiet?
						logger.level = Logger::WARN
					else
						logger.level = Logger::INFO
					end
				end
			end
			
			def configuration
				@options[:configuration]
			end
			
			def context(root = self.root)
				Context.new(root, configuration: configuration)
			end
			
			def invoke(program_name: File.basename($0))
				if @options[:version]
					puts "teapot v#{Teapot::VERSION}"
				elsif @options[:help] or @command.nil?
					print_usage(program_name)
				else
					track_time do
						@command.invoke(self)
					end
				end
			end
		end
	end
end
