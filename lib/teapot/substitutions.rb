# Copyright, 2013, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

module Teapot
	class Indentation
		def initialize(level, indent)
			@level = level
			@indent = indent
		end

		def indentation
			@indentation ||= (@indent * @level)
		end

		def + other
			indentation + other
		end

		def << text
			text.gsub(/^/){|m| m + indentation}
		end

		def by(depth)
			Indentation.new(@level + depth, @indent)
		end
	end
	
	class Substitutions
		def initialize
			@ordered = []
		end
		
		def []= keyword, value
			if Array === value
				open, close = *value.each_slice(value.length / 2)
				@ordered << NestedSubstitution.new(keyword, open, close)
			else
				@ordered << SymbolicSubstitution.new('$' + keyword, value.to_s)
			end
		end

		def << substitution
			@ordered << substition
		end

		attr :ordered

		def apply(text)
			return text unless @ordered.count
			
			grouped = [[@ordered.first]]
			
			@ordered.drop(1).each do |substitution|
				if grouped.last[0].class == substitution.class
					grouped.last << substitution
				else
					grouped << [substitution]
				end
			end
			
			grouped.each do |group|
				text = group.first.class.apply(text, group)
			end
			
			return text
		end
		
		class SymbolicSubstitution
			def initialize(keyword, value)
				@keyword = keyword
				@value = value
			end

			attr :keyword
			attr :value

			def apply(text)
				text.gsub(@keyword, @value)
			end

			def self.apply(text, group)
				substitutions = Hash[group.collect{|substitution| [substitution.keyword, substitution.value]}]

				pattern = Regexp.new(substitutions.keys.map{|key| Regexp.escape(key)}.join('|'))

				text.gsub(pattern) {|key| substitutions[key]}
			end
		end

		class NestedSubstitution
			def initialize(keyword, open, close, indent = "\t")
				@keyword = keyword

				@open = open
				@close = close

				puts "open: #{@open} close: #{@close}"

				@indent = indent
			end

			def line_pattern(prefix = '')
				tag_pattern = Regexp.escape('<' + prefix + @keyword + '>')
				
				# Line matching pattern:
				Regexp.new('^(.*?)' + tag_pattern + '(.*)$', Regexp::MULTILINE | Regexp::EXTENDED)
			end

			def apply(text, level = 0)
				open_pattern = line_pattern
				close_pattern = line_pattern('/')

				lines = text.each_line
				output = StringIO.new

				indent = lambda do |level|
					indentation = Indentation.new(level, @indent)

					while line = lines.next rescue nil
						puts line.inspect
						
						if line =~ open_pattern
							depth = @open.size

							(0...depth).each do |i|
								output.write(indentation.by(i) << ($1 + @open[i] + $2))
							end

							indent[level + depth]

							(0...depth).reverse_each do |i|
								output.write(indentation.by(i) << ($1 + @close[-1 - i] + $2))
							end
						elsif line =~ close_pattern
							break
						else
							output.write(indentation + line)
						end
					end
				end

				indent[0]

				return output.string
			end

			def self.apply(text, group)
				group.each do |substitution|
					text = substitution.apply(text)
				end
				
				return text
			end
		end
	end
end
