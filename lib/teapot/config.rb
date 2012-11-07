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

module Teapot
	class Config
		class Record
			def initialize(config, klass, name, options = {})
				@config = config
				@klass = klass
				
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
			
			attr :klass
			attr :name
			attr :uri
			attr :options
			
			def load(context)
				context.load(self)
			end
			
			def loader_path
				if @klass == Package
					"package.rb"
				elsif @klass == Platform
					"platform.rb"
				end
			end
			
			def destination_path
				@config.base_path_for_record(self) + @name
			end
			
			def to_s
				"<#{@klass} #{@name}>"
			end
		end
		
		def base_path_for_record(record)
			if record.klass == Package
				packages_path
			elsif record.klass == Platform
				platforms_path
			end
		end
		
		def initialize(root, options = {})
			@root = Pathname.new(root)
			@options = options
		
			@packages = []
			@platforms = []
		end

		def packages_path
			@root + (@options[:packages_path] || "packages")
		end
		
		def platforms_path
			@root + (@options[:platforms_path] || "platforms")
		end
		
		def build_path
			@root + (@options[:build_path] || "build")
		end
		
		attr :options
		attr :packages
		attr :platforms

		def source(path)
			@options[:source] = path
		end

		def records
			@packages + @platforms
		end

		def package(name, options = {})
			@packages << Record.new(self, Package, name, options)
		end

		def platform(name, options = {})
			@platforms << Record.new(self, Platform, name, options)
		end

		def self.load(root = Dir.getwd, options = {})
			config = new(root, options)
			
			teapot_path = File.join(root, "Teapot")
			
			if File.exist? teapot_path
				config.instance_eval(File.read(teapot_path), teapot_path)
			end
			
			return config
		end
	end
end
