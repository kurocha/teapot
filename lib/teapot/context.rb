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

require 'teapot/package'
require 'teapot/platform'

module Teapot
	PACKAGE_FILE = "package.rb"

	class Context
		def initialize(config)
			@config = config

			@packages = {}
			@platforms = {}

			@defined = []
		end

		attr :config
		attr :packages
		attr :platforms

		def load(record)
			@record = record
			@defined = []
			
			path = (record.destination_path + record.loader_path).to_s
			self.instance_eval(File.read(path), path)
			
			@defined
		end

		def define_package(name, &block)
			package = Package.new(self, name, @record.destination_path)

			yield(package)

			@packages[package.name] = package

			@defined << package
		end
		
		def define_platform(name, &block)
			platform = Platform.new(self, name)

			yield(platform)

			if platform.available?
				@platforms[platform.name] = platform
			end

			@defined << platform
		end
	end
end
