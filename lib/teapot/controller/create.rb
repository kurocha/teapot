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

require 'teapot/controller'
require 'teapot/controller/fetch'

require 'teapot/name'

module Teapot
	class Controller
		def create(project_name, source, packages)
			name = Name.new(project_name)
			
			log "Creating project named #{project_name} at path #{@root}...".color(:cyan)
			
			File.open(@root + TEAPOT_FILE, "w") do |output|
				output.puts "\# Teapot configuration generated at #{Time.now.to_s}", ''
			
				output.puts "required_version #{VERSION.dump}", ''
			
				output.puts "define_configuration #{name.target.dump} do |configuration|"
			
				output.puts "\tconfiguration[:source] = #{source.dump}", ''
			
				packages.each do |name|
					output.puts "\tconfiguration.import! #{name.dump}"
				end
			
				output.puts "end"
			end

			fetch
		end
	end
end
