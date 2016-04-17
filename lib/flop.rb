# FLexible Option Parser
module Flop
	class Flags
		def initialize(text)
			@text = text
			
			@ordered = text.split(/\s+\|\s+/).map{|part| Flag.new(part)}
		end
		
		def each(&block)
			@ordered.each(&block)
		end
		
		def to_s
			'[' + @ordered.join(' | ') + ']'
		end
		
		def parse(input)
			@ordered.each do |flag|
				if result = flag.parse(input)
					return result
				end
			end
			
			return nil
		end
	end
	
	class Value
		def initialize(flag, value)
			@flag = flag
			@value = value
		end
		
		attr :flag
		attr :value
		
		def to_str
			@value
		end
		
		def inspect
			"#<#{self.class} #{@flag} #{value.inspect}>"
		end
	end
	
	class Flag
		def initialize(text)
			@text = text
			
			if text =~ /(.*?)\s(\<.*?\>)/
				@prefix = $1
				@value = $2
			else
				@prefix = @text
			end
		end
		
		attr :text
		attr :prefix
		attr :value
		
		def to_s
			@text
		end
		
		def parse(input)
			if @prefix == input.first
				if @value
					Value.new(*input.shift(2))
				else
					input.shift
				end
			end
		end
	end
	
	class Option
		def initialize(flags, description, **options)
			@flags = Flags.new(flags)
			@description = description
			
			@type = options[:type]
			@key = options[:key]
			@default = options[:default]
		end
		
		attr :flags
		attr :description
		attr :type
		
		attr :key
		
		def parse(input)
			@flags.parse(input)
		end
		
		def to_s
			@flags
		end
		
		def to_a
			[@flags, @description]
		end
	end
	
	class Options
		def self.parse(*args, **options, &block)
			options = self.new(*args, **options)
			
			options.instance_eval(&block) if block_given?
			
			return options
		end
		
		def initialize(title = "Options", key: :options)
			@title = title
			@ordered = []
			@keyed = {}
			@key = key
		end
		
		attr :key
		
		def option(*args, **options)
			self << Option.new(*args, **options)
		end
		
		def << option
			@ordered << option
			option.flags
		end
		
		def parse(input)
			values = []
			
			while option = @keyed[input.first]
				values << option.parse(input)
			end
			
			return values
		end
		
		def to_a
			["Options:"]
		end
		
		def usage
			@ordered.each do |option|
				puts "\t" + option.to_a.join("\t")
			end
		end
	end
	
	class Nested
		def initialize(name, commands, key: :command)
			@name = name
			@commands = commands
			@key = key
		end
		
		attr :key
		
		def to_s
			@name
		end
		
		def to_a
			[@name, "One of #{@commands.keys.join(', ')}"]
		end
		
		def parse(input)
			if command = @commands[input.first]
				input.shift
				
				puts "Instantiating #{command} with #{input}"
				command.new(input)
			end
		end
		
		def usage
			@commands.each do |key, klass|
				klass.usage(key)
			end
		end
	end
	
	class One
		def initialize(key, description, pattern: //)
			@key = key
			@description = description
			@pattern = pattern
		end
		
		attr :key
		
		def to_s
			"<#{@key}>"
		end
		
		def to_a
			[to_s, @description]
		end
		
		def parse(input)
			if input.first =~ @pattern
				input.shift
			end
		end
	end
	
	class Many
		def initialize(key, description, stop: /^-/)
			@key = key
			@description = description
			@stop = stop
		end
		
		attr :key
		
		def to_s
			"<#{key}...>"
		end
		
		def to_a
			[to_s, @description]
		end
		
		def parse(input)
			if @stop and stop_index = input.index{|item| @stop === item}
				input.shift(stop_index)
			else
				input.shift(input.size)
			end
		end
	end
	
	class Split
		def initialize(key, description, marker: '--')
			@key = key
			@description = description
			@marker = marker
		end
		
		attr :key
		
		def to_s
			"#{@marker} <#{@key}...>"
		end
		
		def to_a
			[to_s, @description]
		end
		
		def parse(input)
			if offset = input.index(@marker)
				input.pop(input.size - offset).tap(&:shift)
			end
		end
	end
	
	class Table
		def initialize
			@rows = []
			@parser = []
		end
		
		attr :rows
		
		def << row
			@rows << row
			
			if row.respond_to?(:parse)
				@parser << row
			end
		end
		
		def usage
			items = Array.new
			
			@rows.each do |row|
				items << row.to_s
			end
			
			items.join(' ')
		end
		
		def parse(input)
			@parser.each do |row|
				puts "Trying #{row} with #{input}"
				if result = row.parse(input)
					yield row.key, result, row
				end
			end
		end
	end
	
	class Command
		def initialize(input)
			self.class.table.parse(input) do |key, value|
				self.send("#{key}=", value)
			end
		end
		
		def [] key
			@attributes[key]
		end
		
		class << self
			attr_accessor :description
		end
		
		def self.table
			@table ||= Table.new
		end
		
		def self.append(row)
			attr_accessor(row.key) if row.respond_to?(:key)
			
			self.table << row
		end
		
		def self.options(*args, **options, &block)
			append Options.parse(*args, **options, &block)
		end
		
		def self.nested(*args, **options)
			append Nested.new(*args, **options)
		end
		
		def self.one(*args, **options)
			append One.new(*args, **options)
		end
		
		def self.many(*args, **options)
			append Many.new(*args, **options)
		end
		
		def self.split(*args, **options)
			append Split.new(*args, **options)
		end
		
		def self.usage(name)
			return unless @table
			
			puts "#{name} #{@table.usage}"
			@table.rows.each do |row|
				puts "\t" + row.to_a.join("\t")
				
				if row.respond_to?(:usage)
					row.usage
				end
			end
		end
	end
end