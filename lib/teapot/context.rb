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
require 'rainbow'

require 'teapot/package'

module Teapot
	INFUSION_VERSION = "0.5"
	
	class IncompatibleInfusion < StandardError
	end
	
	class Infusion
		def initialize(context, record)
			@context = context
			@record = record
			
			@defined = []
			@version = nil
		end
		
		attr :record
		attr :defined
		attr :version
		
		def required_version(version)
			if version <= INFUSION_VERSION
				@version = version
			else
				raise IncompatibleInfusion.new("Version #{version} more recent than #{INFUSION_VERSION}!")
			end
		end

		def define_package(*args, &block)
			package = Package.new(@context, @record, *args)

			yield(package)

			@context.packages[package.name] = package

			@defined << package
		end
		
		def load(path)
			self.instance_eval(File.read(path), path)
		end
	end
	
	class Context
		def initialize(config)
			@config = config

			@selection = nil

			@packages = {}

			@dependencies = []
			@selection = Set.new
		end

		attr :config
		attr :packages

		def select(names)
			names.each do |name|
				if @packages.key? name
					@selection << name
				else
					@dependencies << name
				end
			end
		end
		
		attr :dependencies
		attr :selection
		
		def load(record)
			infusion = Infusion.new(self, record)
			
			path = (record.package_path + record.loader_path).to_s
			infusion.load(path)
			
			if infusion.version == nil
				raise IncompatibleInfusion.new("No version specified in #{path}!")
			end
			
			infusion.defined
		end
	end
end
