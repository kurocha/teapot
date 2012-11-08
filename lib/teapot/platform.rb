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

require 'fileutils'
require 'rexec/environment'

module Teapot
	class Platform
		class Config
			def initialize(values = {})
				@values = values
			end
		
			attr :values
		
			def method_missing(name, *args)
				if name.to_s.match(/^(.*?)(\=)?$/)
					if $2
						return @values[$1.to_sym] = args[0]
					else
						return @values[$1.to_sym]
					end
				else
					super(name, *args)
				end
			end
			
			def merge(config)
				Config.new(@values.merge(config))
			end
		end
	
		def prefix
			@context.config.build_path + @name.to_s
		end
	
		def cmake_modules_path
			prefix + "share/cmake/modules"
		end
	
		def initialize(context, name)
			@context = context
			
			@name = name
			@config = nil
			@available = false
		end
		
		attr :name
		
		def configure(&block)
			@configuration = Proc.new &block
		end
		
		def config
			if available?
				config = Config.new
			
				@configuration.call(config)
			
				return config
			else
				return nil
			end
		end
		
		def make_available!
			@available = true
		end
		
		def available?
			@available
		end
		
		def to_s
			"<Platform #{@name}: #{@availble ? 'available' : 'inactive'}>"
		end
		
		def prepare!
			FileUtils.mkdir_p cmake_modules_path
		end
	end
end
