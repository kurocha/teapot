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

require 'teapot/build/target'
require 'digest/md5'

module Teapot
	module Build
		module Targets
			class External < Build::Target
				# This file contains a checksum of the build environment. If it changes, even though the source code hasn't changed, it means that we need to recompile.
				ENVIRONMENT_CHECKSUM_FILE = ".teapot-environment-checksum"
				
				def initialize(parent, directory, &block)
					super parent
					
					@directory = directory
					
					# Callback for preparing the target and compiling/installing the target.
					@install = block
				end
				
				def root
					@parent.root + @directory
				end
				
				def build(values)
					return unless @install
					
					source_path = @parent.root + @directory
					build_source_path = values[:build_prefix] + @directory
					build_source_checksum_path = build_source_path + ENVIRONMENT_CHECKSUM_FILE
					
					fresh = false
					
					# Check the environment checksum to catch any changes to the build environment:
					if build_source_checksum_path.exist? and File.read(build_source_checksum_path.to_s) != checksum(values)
						FileUtils.rm_rf(build_source_path.to_s) if build_source_path.exist?
					end
					
					if !build_source_path.exist?
						build_source_path.mkpath
						
						FileUtils.cp_r(source_path.children, build_source_path.to_s)
						
						# Write the environment checksum out to a file:
						File.write(build_source_checksum_path, checksum(values))
						
						fresh = true
					end
					
					# Convert the hash to suit typical shell specific arguments:
					shell_environment = Environment::System::convert_to_shell(values)
					
					Dir.chdir(build_source_path) do
						RExec.env(shell_environment) do
							@install.call(Environment::Evaluator.new(values), fresh)
						end
					end
				end
				
				private
				
				def checksum(values)
					# Calculate a canonical text representation of the environment:
					text = values.sort.inspect
					
					# Digest the text:
					Digest::MD5.hexdigest(text)
				end
			end
		end
	end
end
