
require 'set'
require 'pathname'

module FSO
	module Files
		class List
			include Enumerable
			
			def +(list)
				Composite.new([self, list])
			end
			
			def intersects? other
				other.any?{|path| include?(path)}
			end
			
			def rebase(root)
				raise NotImplementedError
			end
			
			def to_paths
				relative_paths = self.each do |path|
					path.relative_path
				end
				
				return Paths.new(@root, relative_paths)
			end
			
			def match(pattern)
				all? {|path| path.match(pattern)}
			end
		end
		
		class RelativePath < String
			# Both paths must be full absolute paths, and path must have root as an prefix.
			def initialize(path, root)
				raise ArgumentError.new("#{root} is not a prefix of #{path}") unless path.start_with?(root)
				
				super path
				
				@root = root
			end
			
			attr :root
			
			def relative_path
				self.slice(@root.length..-1)
			end
		end
		
		class Directory < List
			def initialize(root, path = "")
				@root = root.to_s
				@path = path
			end
			
			attr :root
			attr :path
			
			def full_path
				File.join(@root, @path)
			end
			
			def each(&block)
				Dir.glob(full_path + "**/*").each do |path|
					yield RelativePath.new(path, @root)
				end
			end
			
			def roots
				[full_path]
			end
			
			def eql?(other)
				other.kind_of?(self.class) and @root.eql?(other.root) and @path.eql?(other.path)
			end
			
			def hash
				[@root, @path].hash
			end
			
			def include?(path)
				# Would be true if path is a descendant of full_path.
				path.start_with?(full_path)
			end
			
			def rebase(root)
				self.class.new(root, @path)
			end
		end
		
		class Glob < List
			def initialize(root, pattern)
				@root = root.to_s
				@pattern = pattern
			end
		
			attr :root
			attr :pattern
			
			def full_pattern
				File.join(@root, @pattern)
			end
			
			# Enumerate all paths matching the pattern.
			def each(&block)
				Dir.glob(full_pattern).each do |path|
					yield RelativePath.new(path, @root)
				end
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
			
			def rebase(root)
				self.class.new(root, @pattern)
			end
		end
		
		class Paths < List
			def initialize(root, paths)
				@root = root.to_s
				@paths = Array(paths)
			end
		
			attr :paths
		
			def each(&block)
				@paths.each do |path|
					full_path = File.join(@root, path)
					yield RelativePath.new(full_path, @root)
				end
			end
		
			def roots
				[@root]
			end
			
			def eql? other
				other.kind_of?(self.class) and @paths.eql?(other.paths)
			end
			
			def hash
				@paths.hash
			end
			
			def include?(path)
				# Perhaps implement this locally:
				relative_path = Pathname(path).relative_path_from(Pathname(@root)).to_s
				
				@paths.include?(relative_path)
			rescue
				return false
			end
			
			def rebase(root)
				self.class.new(root, @paths)
			end
			
			def to_paths
				return self
			end
		end
		
		class Composite < List
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
					raise ArgumentError.new("Cannot merge non-list of file paths.")
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
			
			def rebase(root)
				self.class.new(@files.collect{|list| list.rebase(root)})
			end
			
			def to_paths
				Composite.new(@files.collect(&:to_paths))
			end
			
			def self.[](files)
				if files.size == 0
					return None
				elsif files.size == 1
					files.first
				else
					self.class.new(files)
				end
			end
		end
		
		None = Composite.new
	end
end
