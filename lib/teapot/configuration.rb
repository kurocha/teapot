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
	class Configuration < Definition
		include Dependency
		
		def initialize(context, package, name)
			super context, package, name

			@source = nil
			@packages = []
			@environment = Environment.new
		end
		
		# The source against which other packages may be fetched:
		attr :source, true
		
		# A list of packages which are required by this configuration:
		attr :packages

		# Configuration specific environment:
		attr :environment

		def package(name, options = {})
			@packages << Package.new(packages_path + name.to_s, name, options)
		end

		def packages_path
			context.root + "teapot/packages/#{name}"
		end
		
		def platforms_path
			context.root + "teapot/platforms/#{name}"
		end
		
		def load_all
			@packages.each do |package|
				@context.load(package)
			end
		end
	end
end
