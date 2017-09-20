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
require 'build/name'

require_relative 'fetch'
require 'rugged'

module Teapot
	module Command
		class Create < Samovar::Command
			self.description = "Create a new teapot package using the specified repository."
			
			one :project_name, "The name of the new project in title-case, e.g. 'My Project'."
			one :source, "The source repository to use for fetching packages, e.g. https://github.com/kurocha."
			many :packages, "Any additional packages you'd like to include in the project."
			
			def invoke(parent)
				raise ArgumentError, "project_name is required" unless @project_name
				raise ArgumentError, "source is required" unless @source
				
				logger = parent.logger
				
				nested = parent['--root', parent.options[:root] || project_name.gsub(/\s+/, '-').downcase]
				root = nested.root
				
				if root.exist?
					raise ArgumentError.new("#{root} already exists!")
				end
				
				# Create and set the project root:
				root.create
				
				repository = Rugged::Repository.init_at(root.to_s)
				
				logger.info "Creating project named #{project_name} at path #{root}...".color(:cyan)
				generate_project(root, @project_name, @source, @packages)
				
				# Fetch the initial packages:
				Fetch[].invoke(nested)
				
				context = nested.context
				selection = context.select
				target_names =  selection.configuration.targets[:create]
				
				if target_names.any?
					# Generate the initial project files:
					Build[*target_names].invoke(nested)
					
					# Fetch any additional packages:
					Fetch[].invoke(nested)
				end
				
				# Stage all files:
				index = repository.index
				index.add_all
				
				# Commit the initial project files:
				Rugged::Commit.create(repository,
					tree: index.write_tree(repository),
					message: "Initial project files.",
					parents: repository.empty? ? [] : [repository.head.target].compact,
					update_ref: 'HEAD'
				)
			end
			
			def generate_project(root, project_name, source, packages)
				name = ::Build::Name.new(project_name)
				
				# Otherwise the initial commit will try to include teapot/
				File.open(root + ".gitignore", "w") do |output|
					output.puts "teapot/"
				end
				
				# A very basic teapot file to pull in the initial dependencies.
				File.open(root + TEAPOT_FILE, "w") do |output|
					output.puts "\# Teapot v#{VERSION} configuration generated at #{Time.now.to_s}", ''
				
					output.puts "required_version #{LOADER_VERSION.dump}", ''
					
					output.puts "define_project #{name.target.dump} do |project|"
					output.puts "\tproject.title = #{name.text.dump}"
					output.puts "end", ''
				
					output.puts "\# Build Targets", ''
				
					output.puts "\# Configurations", ''
					
					output.puts "define_configuration 'development' do |configuration|"
					output.puts "\tconfiguration[:source] = #{source.dump}"
					output.puts "\tconfiguration.import #{name.target.dump}"
					packages.each do |name|
						output.puts "\tconfiguration.require #{name.dump}"
					end
					output.puts "end", ''
					
					output.puts "define_configuration #{name.target.dump} do |configuration|"
					output.puts "\tconfiguration.public!"
					output.puts "end"
				end
			end
		end
	end
end
