
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
