
require 'set'

module FSO
	module Files
		class List
			def +(list)
				Composite.new([self, list])
			end
			
			def intersects? other
				other.any?{|path| include?(path)}
			end
		end
		
		class Glob < List
			include Enumerable
		
			def initialize(root, pattern)
				@root = root
				@pattern = pattern
			end
		
			attr :root
			attr :pattern
			
			def full_pattern
				File.join(@root, @pattern)
			end
			
			# Enumerate all paths matching the pattern.
			def each(&block)
				Dir.glob(full_pattern).each &block
			end
		
			def roots
				[@root]
			end
			
			def eql?(other)
				other.kind_of?(self.class) and @root.eql?(other.root) and @pattern.eql?(other.pattern)
			end
			
			def hash
				[@root, @pattern].hash
			end
			
			def include?(path)
				File.fnmatch(full_pattern, path)
			end
		end
		
		def glob(pattern, root = "./")
			Files::Glob.new(File.realpath(root), pattern)
		end
		
		class Paths < List
			include Enumerable
		
			def initialize(paths)
				@paths = paths
			end
		
			attr :paths
		
			def each(&block)
				@paths.each &block
			end
		
			def roots
				@paths.collect do |path|
					File.realpath(File.directory?(path) ? path : File.dirname(path))
				end.uniq
			end
			
			def eql? other
				other.kind_of?(self.class) and @paths.eql?(other.paths)
			end
			
			def hash
				@paths.hash
			end
			
			def include?(path)
				@paths.include?(path)
			end
		end
		
		def paths(*paths)
			Files::Paths.new(paths)
		end
		
		class Composite < List
			include Enumerable
			
			def initialize(files = Set.new)
				@files = files
			end
			
			attr :files
			
			def each(&block)
				@files.each do |files|
					files.each &block
				end
			end
			
			def roots
				@files.collect(&:roots).flatten.uniq
			end
			
			def eql?(other)
				other.kind_of?(self.class) and @files.eql?(other.files)
			end
			
			def hash
				@files.hash
			end
			
			def merge(list)
				if list.kind_of? Composite
					@files += list.files
				elsif list.kind_of? List
					@files << list
				else
					@files << Paths.new(Array(list))
				end
			end
			
			def +(list)
				if list.kind_of? Composite
					Composite.new(@files + list.files)
				else
					Composite.new(@files + [list])
				end
			end
			
			def include?(path)
				@files.any? {|list| list.include?(path)}
			end
		end
	end
end
