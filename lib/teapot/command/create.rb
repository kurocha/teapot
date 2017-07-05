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

module Teapot
	module Command
		class Create < Samovar::Command
			self.description = "Create a new teapot package using the specified repository."
			
			one :project_name, "The name of the new project in title-case, e.g. 'My Project'."
			one :source, "The source repository to use for fetching packages, e.g. https://github.com/kurocha."
			many :packages, "Any additional packages you'd like to include in the project."
			
			def invoke(parent)
				logger = parent.logger
				
				nested = parent['--root', parent.options[:root] || project_name.gsub(/\s+/, '-').downcase]
				root = nested.root
				
				if root.exist?
					raise ArgumentError.new("#{root} already exists!")
				end
				
				# Create and set the project root:
				root.create
				
				Teapot::Repository.new(root).init!
				
				logger.info "Creating project named #{project_name} at path #{root}...".color(:cyan)
				generate_project(root, @project_name, @source, @packages)
				
				# Fetch the initial packages:
				Fetch[].invoke(nested)
				
				context = nested.context
				
				# Generate the default project if it is possible to do so:
				if context.generators.include?('project')
					Generate['--force', 'project', project_name].invoke(nested)
				end
				
				# Fetch any additional packages:
				Fetch[].invoke(nested)
			end
			
			def generate_project(root, project_name, source, packages)
				name = ::Build::Name.new(project_name)
				
				File.open(root + TEAPOT_FILE, "w") do |output|
					output.puts "\# Teapot v#{VERSION} configuration generated at #{Time.now.to_s}", ''
				
					output.puts "required_version #{LOADER_VERSION.dump}", ''
				
					output.puts "\# Build Targets", ''
				
					output.puts "\# Configurations", ''
				
					output.puts "define_configuration #{name.target.dump} do |configuration|"
					
					output.puts "\tconfiguration[:source] = #{source.dump}", ''
				
					packages.each do |name|
						output.puts "\tconfiguration.require #{name.dump}"
					end
				
					output.puts "end", ''
				end
			end
		end
	end
end
