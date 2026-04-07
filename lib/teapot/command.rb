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
	# @namespace
	module Command
		# Represents the top-level command for the teapot CLI.
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
			
			# The project root directory, either from --root option or current working directory.
			# @returns [Build::Files::Path] The root directory path.
			def root
				::Build::Files::Path.expand(@options[:root] || Dir.getwd)
			end
			
			# Whether verbose logging is enabled via --verbose flag.
			# @returns [Boolean] True if verbose mode is enabled.
			def verbose?
				@options[:logging] == :verbose
			end
			
			# Whether quiet logging is enabled via --quiet flag.
			# @returns [Boolean] True if quiet mode is enabled.
			def quiet?
				@options[:logging] == :quiet
			end
			
			# Get the logger for the command.
			# @returns [Console::Logger] The configured logger instance.
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
			
			# The build configuration name from -c option or TEAPOT_CONFIGURATION environment variable.
			# @returns [String | Nil] The configuration name if specified.
			def configuration
				@options[:configuration]
			end
			
			# Create a context for the project.
			# @parameter root [Build::Files::Path] The root directory path.
			# @returns [Context] A new context instance.
			def context(root = self.root)
				Context.new(root, configuration: configuration)
			end
			
			# Execute the command.
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
