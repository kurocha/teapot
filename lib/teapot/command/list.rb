# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "samovar"
require "console/terminal"

require_relative "selection"

module Teapot
	module Command
		class List < Selection
			self.description = "List provisions and dependencies of the specified package."
			
			def terminal(output = $stdout)
				Console::Terminal.for(output).tap do |terminal|
					terminal[:definition] = terminal.style(nil, nil, :bright)
					terminal[:dependency] = terminal.style(:blue)
					terminal[:provision] = terminal.style(:green)
					terminal[:package] = terminal.style(:yellow)
					terminal[:import] = terminal.style(:cyan)
					terminal[:error] = terminal.style(:red)
				end
			end
			
			def process(selection)
				context = selection.context
				terminal = self.terminal
				
				selection.resolved.each do |package|
					terminal.puts "Package #{package.name} (from #{package.path}):"
					
					begin
						script = context.load(package)
						definitions = script.defined
						
						definitions.each do |definition|
							terminal.puts "\t#{definition}", style: :definition
							
							definition.description.each_line do |line|
								terminal.puts "\t\t#{line.chomp}", style: :description
							end if definition.description
							
							case definition
							when Project
								terminal.puts "\t\t- Summary: #{definition.summary}" if definition.summary
								terminal.puts "\t\t- License: #{definition.license}" if definition.license
								terminal.puts "\t\t- Website: #{definition.website}" if definition.website
								terminal.puts "\t\t- Version: #{definition.version}" if definition.version
								
								definition.authors.each do |author|
									contact_text = [author.email, author.website].compact.collect{|text| " <#{text}>"}.join
									terminal.puts "\t\t- Author: #{author.name}" + contact_text
								end
							when Target
								definition.dependencies.each do |dependency|
									terminal.puts "\t\t- #{dependency}", style: :dependency
								end
								
								definition.provisions.each do |name, provision|
									terminal.puts "\t\t- #{provision}", style: :provision
								end
							when Configuration
								definition.packages.each do |package|
									terminal.puts "\t\t- #{package}", style: :package
								end
								
								definition.imports.select(&:explicit).each do |import|
									terminal.puts "\t\t- import #{import.name}", style: :import
								end
							end
						end
					rescue MissingTeapotError => error
						terminal.puts "\t#{error.message}", style: :error
					rescue IncompatibleTeapotError => error
						terminal.puts "\t#{error.message}", style: :error
					end
				end
			end
		end
	end
end
