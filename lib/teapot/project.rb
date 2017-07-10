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

require_relative 'definition'

module Teapot
	class Project < Definition
		Author = Struct.new(:name, :email, :website)
		
		def initialize(context, package, name)
			super context, package, name
			
			@version = "0.0.0"
			@authors = []
		end
		
		def name
			if @title
				# Prefer title, it retains case.
				Build::Name.new(@title)
			else
				# Otherwise, if we don't have title, use the target name.
				Build::Name.from_target(@name)
			end
		end
		
		def freeze
			@title.freeze
			@summary.freeze
			@license.freeze
			@website.freeze
			@version.freeze
			
			@authors.freeze
			
			super
		end
		
		attr_accessor :title
		attr_accessor :summary
		attr_accessor :license
		attr_accessor :website
		attr_accessor :version
		
		attr :authors
		
		def add_author(name, options = {})
			@authors << Author.new(name, options[:email], options[:website])
		end
	end
end
