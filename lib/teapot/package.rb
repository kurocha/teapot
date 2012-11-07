
require 'pathname'

module Teapot
	class Package
		class BuildError < StandardError
		end

		class Task
			def initialize
				@callbacks = {}
			end
			
			def define(name, &callback)
				@callbacks[name] = callback
			end
			
			def [](name)
				@callbacks[name] || @callbacks[:all]
			end
		end

		def self.build_order(available, packages)
			ordered = []

			expand = lambda do |name|
				package = available[name]

				unless package
					puts "Couldn't resolve #{name}"
				else
					package.depends.each do |dependency|
						expand.call(dependency)
					end

					unless ordered.include? package
						ordered << package
					end
				end
			end

			packages.each do |package|
				expand.call(package.name)
			end

			return ordered
		end

		def initialize(context, name, path = nil)
			@context = context
			
			parts = name.split('-')
			@name = parts[0..-2].join('-')
			@version = parts[-1]

			@path = path || (context.config.packages_path + @name)

			@build = Task.new

			@depends = []

			@source_path = @path + name
			@fetch_location = nil
		end

		attr :name
		attr :version
		attr :path
		attr :variants
		attr :fetch_location

		attr :depends, true
		attr :source_path, true

		def install!
			if @fetch_location
			end
		end

		def build(platform, &block)
			@build.define(platform, &block)
		end

		def build!(platform = :all, config = {})
			task = @build[platform.name]
			
			puts "Building #{@name} for #{platform.name}"
			if task
				Dir.chdir(@path) do
					puts "Entering #{@path}..."
					task.call(platform, platform.config.merge(config))
				end
			else
				raise BuildError.new("Could not find task #{task_name} for #{platform.name}!")
			end
		end

		def fetch_from(location)
			@fetch_location = location
		end

		def to_s
			"<Package: #{@name}>"
		end
	end
end
