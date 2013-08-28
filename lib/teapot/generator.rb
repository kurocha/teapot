# Copyright, 2013, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'teapot/definition'
require 'teapot/substitutions'
require 'teapot/merge'

require 'tempfile'

module Teapot
	class GeneratorError < StandardError
		def initialize(message, generator = nil)
			super(message)
			
			@generator = generator
		end
		
		attr :generator
	end
	
	class Generator < Definition
		def initialize(context, package, name)
			super context, package, name

			@generate = nil
		end

		def generate(&block)
			@generate = Proc.new(&block)
		end

		def generate!(*args)
			@generate[*args]
		end

		def substitute(text, substitutions)
			return text unless substitutions

			if Hash === substitutions
				pattern = Regexp.new(substitutions.keys.map{|x| Regexp.escape(x)}.join('|'))

				text.gsub(pattern) {|key| substitutions[key]}
			else
				substitutions.call(text)
			end
		end

		def write(source, destination, substitutions = nil, mode = "a")
			source_path = Pathname(path) + source
			destination_path = Pathname(context.root) + destination

			destination_path.dirname.mkpath

			File.open(destination_path, mode) do |file|
				text = File.read(source_path)

				file.write substitute(text, substitutions)
			end
		end

		def append(source, destination, substitutions = nil)
			write(source, destination, substitutions, "a")
		end

		def merge(source, destination, substitutions = nil)
			source_path = Pathname(path) + source
			destination_path = Pathname(context.root) + destination

			if destination_path.exist?
				temporary_file = Tempfile.new(destination_path.basename.to_s)

				# This functionality works, but needs improvements.
				begin
					# Need to ask user what to do?
					write(source_path, temporary_file.path, substitutions, "w")

					result = Merge::combine(destination.readlines, temporary_file.readlines)

					destination.open("w") do |file|
						file.write result.join
					end
				ensure
					temporary_file.unlink
				end
			else
				write(source_path, destination_path, substitutions, "w")
			end
		end

		def is_binary(path)
			if path.exist?
				return path.read(1024).bytes.find{|byte| byte >= 0 and byte <= 6}
			else
				return false
			end
		end

		def copy_binary(source_path, destination_path)
			destination_path.dirname.mkpath
			FileUtils.cp source_path, destination_path
		end

		def copy(source, destination, substitutions = nil)
			source_path = Pathname(path) + source
			destination_path = Pathname(context.root) + destination

			if source_path.directory?
				source_path.children(false).each do |child_path|
					copy(source_path + child_path, destination_path + substitute(child_path.to_s, substitutions), substitutions)
				end
			else
				if is_binary(source_path) or is_binary(destination)
					destination_path = Pathname(context.root) + destination
					copy_binary(source_path, destination_path)
				else
					merge(source_path, destination, substitutions)
				end
			end
		end
	end
end
