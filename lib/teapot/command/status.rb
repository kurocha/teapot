# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require_relative "selection"
require "rugged"
require "console/terminal"

module Teapot
	module Command
		# A command to show git status of packages.
		class Status < Selection
			self.description = "List the git status of the specified package(s)."
			
			# Create a terminal with custom styles for colorizing git status information.
			# @parameter output [IO] The output stream.
			# @returns [Console::Terminal] The configured terminal.
			def terminal(output = $stdout)
				Console::Terminal.for(output).tap do |terminal|
					terminal[:worktree_new] = terminal.style(:green)
					terminal[:worktree_modified] = terminal.style(:yellow)
					terminal[:worktree_deleted] = terminal.style(:red)
				end
			end
			
			# Open the git repository for a package, or return nil if the package doesn't have a repository yet.
			# @parameter package [Package] The package.
			# @returns [Rugged::Repository | Nil] The repository or nil.
			def repository_for(package)
				Rugged::Repository.new(package.path.to_s)
			rescue Rugged::RepositoryError
				# In some cases, a repository might not exist yet, so just skip the package.
				nil
			end
			
			# Process and display the selection.
			# @parameter selection [Select] The selection to process.
			def process(selection)
				context = selection.context
				terminal = self.terminal
				
				selection.resolved.each do |package|
					if repository = repository_for(package)
						changes = {}
						repository.status do |file, status|
							unless status == [:ignored]
								changes[file] = status
							end
						end
						
						next if changes.empty?
						
						terminal.puts "Package #{package.name} (from #{package.path}):"
						
						changes.each do |file, statuses|
							terminal.puts "\t#{file} (#{statuses})", style: statuses.last
						end
					end
				end
			end
		end
	end
end
