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

require_relative '../controller'
require_relative '../controller/create'

module Teapot
	module Command
		class Create < Samovar::Command
			self.description = "Create a new teapot package using the specified repository."
			
			one :project_name, "The name of the new project in title-case, e.g. 'My Project'."
			one :source, "The source repository to use for fetching packages, e.g. https://github.com/kurocha."
			many :packages, "Any additional packages you'd like to include in the project."
			
			def invoke(parent)
				project_path = parent.root || project_name.gsub(/\s+/, '-').downcase
				root = ::Build::Files::Path.expand(project_path)
				
				if root.exist?
					raise ArgumentError.new("#{root} already exists!")
				end
				
				# Make the path:
				root.create
				
				Teapot::Repository.new(root).init!
				
				parent.controller(root).create(@project_name, @source, @packages)
			end
		end
	end
end
