# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "samovar"

require_relative "command/build"
require_relative "command/clean"
require_relative "command/create"
require_relative "command/clone"
require_relative "command/fetch"
require_relative "command/list"
require_relative "command/status"
require_relative "command/visualize"

require_relative "context"
require_relative "configuration"
require_relative "version"

require "fileutils"

require "console"

module Teapot
	module Command
		class Top < Samovar::Command
			self.description = "A decentralised package manager and build tool."
			
			options do
				option "-c/--configuration <name>", "Specify a specific build configuration.", default: ENV["TEAPOT_CONFIGURATION"]
				option "--root <path>", "Work in the given root directory."
				option "--verbose | --quiet", "Verbosity of output for debugging.", key: :logging
				option "-h/--help", "Print out help information."
				option "-v/--version", "Print out the application version."
			end
			
			nested :command, {
				"create" => Create,
				"clone" => Clone,
				"fetch" => Fetch,
				"list" => List,
				"status" => Status,
				"build" => Build,
				"visualize" => Visualize,
				"clean" => Clean,
			}, default: "build"
			
			def root
				::Build::Files::Path.expand(@options[:root] || Dir.getwd)
			end
			
			def verbose?
				@options[:logging] == :verbose
			end
			
			def quiet?
				@options[:logging] == :quiet
			end
			
			def logger
				@logger ||= Console::Logger.new(Console.logger, verbose: self.verbose?).tap do |logger|
					if verbose?
						logger.debug!
					elsif quiet?
						logger.warn!
					else
						logger.info!
					end
				end
			end
			
			def configuration
				@options[:configuration]
			end
			
			def context(root = self.root)
				Context.new(root, configuration: configuration)
			end
			
			def call
				if @options[:version]
					puts "teapot v#{Teapot::VERSION}"
				elsif @options[:help]
					print_usage(output: $stdout)
				else
					@command.call
				end
			rescue Teapot::IncompatibleTeapotError => error
				logger.error(command, error) do
					"Supported minimum version #{Teapot::MINIMUM_LOADER_VERSION.dump} to #{Teapot::LOADER_VERSION.dump}."
				end
				
				raise
			rescue ::Build::Dependency::UnresolvedDependencyError => error
				logger.error(command, error) do |buffer|
					buffer.puts "Unresolved dependencies:"
					
					error.chain.unresolved.each do |name, parent|
						buffer.puts "#{parent} depends on #{name.inspect}"
						
						conflicts = error.chain.conflicts[name]
						
						if conflicts
							conflicts.each do |conflict|
								buffer.puts " - provided by #{conflict.name}"
							end
						end
					end
					
					buffer.puts "Cannot continue due to unresolved dependencies!"
				end
				
				raise
			rescue StandardError => error
				logger.error(command, error)
				
				raise
			end
		end
	end
end
