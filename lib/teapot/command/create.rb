# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "samovar"
require "build/name"

require_relative "fetch"
require "rugged"

module Teapot
	module Command
		# A command to create a new teapot project.
		class Create < Samovar::Command
			self.description = "Create a new teapot package using the specified repository."
			
			one :name, "The name of the new project in title-case, e.g. 'My Project'.", required: true
			one :source, "The source repository to use for fetching packages, e.g. https://github.com/kurocha.", required: true
			many :packages, "Any packages you'd like to include in the project.", default: ["generate-project"]
			
			# Create a new project directory structure with default teapot.rb configuration.
			def call
				logger = parent.logger
				
				nested = parent["--root", parent.options[:root] || name.gsub(/\s+/, "-").downcase]
				root = nested.root
				
				if root.exist?
					raise ArgumentError.new("#{root} already exists!")
				end
				
				# Create and set the project root:
				root.create
				
				repository = Rugged::Repository.init_at(root.to_s)
				
				logger.info "Creating project named #{name} at path #{root}..."
				generate_project(root, @name, @source, @packages)
				
				# Fetch the initial packages:
				Fetch[parent: nested].call
				
				context = nested.context
				selection = context.select
				target_names =  selection.configuration.targets[:create]
				
				if target_names.any?
					# Generate the initial project files:
					Build[*target_names, parent: nested].call
					
					# Fetch any additional packages:
					Fetch[parent: nested].call
				end
				
				# Stage all files:
				index = repository.index
				index.add_all
				
				# Commit the initial project files:
				Rugged::Commit.create(repository,
					tree: index.write_tree(repository),
					message: "Initial project files.",
					parents: repository.empty? ? [] : [repository.head.target].compact,
					update_ref: "HEAD"
				)
			end
			
			# Generate the initial project files.
			# @parameter root [Build::Files::Path] The project root path.
			# @parameter name [String] The project name.
			# @parameter source [String] The source repository URL.
			# @parameter packages [Array(String)] The packages to include.
			def generate_project(root, name, source, packages)
				name = ::Build::Name.new(name)
				
				# Otherwise the initial commit will try to include teapot/
				File.open(root + ".gitignore", "w") do |output|
					output.puts "teapot/"
				end
				
				# A very basic teapot file to pull in the initial dependencies.
				File.open(root + TEAPOT_FILE, "w") do |output|
					output.puts "\# Teapot v#{VERSION} configuration generated at #{Time.now.to_s}", ""
					
					output.puts "required_version #{LOADER_VERSION.dump}", ""
					
					output.puts "define_project #{name.target.dump} do |project|"
					output.puts "\tproject.title = #{name.text.dump}"
					output.puts "end", ""
					
					output.puts "\# Build Targets", ""
					
					output.puts "\# Configurations", ""
					
					output.puts "define_configuration 'development' do |configuration|"
					output.puts "\tconfiguration[:source] = #{source.dump}"
					output.puts "\tconfiguration.import #{name.target.dump}"
					packages.each do |name|
						output.puts "\tconfiguration.require #{name.dump}"
					end
					output.puts "end", ""
					
					output.puts "define_configuration #{name.target.dump} do |configuration|"
					output.puts "\tconfiguration.public!"
					output.puts "end"
				end
			end
		end
	end
end
