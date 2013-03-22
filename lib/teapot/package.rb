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

require 'pathname'

require 'teapot/context'
require 'teapot/environment'
require 'teapot/commands'

require 'teapot/definition'

module Teapot
	class Package
		def initialize(path, name, options = {})
			@path = path

			if options[:name]
				@name = options[:name]
			end

			if Symbol === name
				@uri = name.to_s
				@name ||= @uri
			else
				@name ||= File.basename(name)
				@uri = name
			end

			@options = options
 		end

		attr :name
		attr :path

		attr :uri
		attr :options


		def local?
			@options.key? :local
		end

		def external?
			@options.key? :source
		end

		def external_url(relative_root)
			base_uri = URI(@options[:source].to_s)

			if base_uri.scheme == nil || base_uri.scheme == 'file'
				base_uri = URI "file://" + File.expand_path(base_uri.path, relative_root) + "/"
			end

			return relative_url(base_uri)
		end

		def to_s
			"<#{self.class.name} #{@name.dump} path=#{path}>"
		end
		
		private
		
		def relative_url(base_uri)
			source_uri = URI(@uri)

			unless source_uri.absolute?
				source_uri = base_uri + source_uri
			end
	
			# Git can't handle the default formatting that Ruby uses for file URIs.
			if source_uri.scheme == "file"
				source_uri = "file://" + source_uri.path
			end

			return source_uri
		end
	end
end
