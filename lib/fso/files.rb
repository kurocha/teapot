
require 'set'
require 'pathname'

module FSO
	module Files
		class List
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
				raise NotImplementedError
			end
		end
		
		class Glob < List
			include Enumerable
		
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
					yield path, @root
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
			
			def to_paths
				relative_paths = []
				root_pathname = Pathname(root)
				
				Dir.glob(full_pattern).each do |path|
					relative_paths << Pathname(path).relative_path_from(root_pathname).to_s
				end
				
				return Paths.new(@root, relative_paths)
			end
		end
		
		class Paths < List
			include Enumerable
		
			def initialize(root, paths)
				@root = root.to_s
				@paths = paths
			end
		
			attr :paths
		
			def each(&block)
				@paths.each do |path|
					yield File.join(@root, path), @root
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
		end
		
		None = Composite.new
	end
end
