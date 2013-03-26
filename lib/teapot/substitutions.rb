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
	module Substitutions
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

			def self.apply(text, substitutions)
				substitutions = Hash[substitutions.collect{|s| [s.keyword, s.value]}]

				pattern = Regexp.new(substitutions.keys.map{|key| Regexp.escape(key)}.join('|'))

				text.gsub(pattern) {|key| substitutions[key]}
			end
		end

		class NestedSubstitution
			def initialize(keyword, open, close, indent = "\t")
				@keyword = keyword

				@open = open
				@close = close

				@indent = indent
			end
	
			def apply(text, level = 0)
				open_pattern = Regexp.new(Regexp.escape('<' + @keyword + '>'))
				close_pattern = Regexp.new(Regexp.escape('</' + @keyword + '>'))

				lines = text.each_line
				output = StringIO.new

				indent = lambda do |level|
					indentation = Indentation.new(level, @indent)

					while line = lines.next rescue nil
						if line =~ open_pattern
							depth = @open.size

							(0...depth).each do |i|
								output.write(indentation.by(i) << @open[i])
							end

							indent[level + depth]

							(0...depth).reverse_each do |i|
								output.write(indentation.by(i) << @close[-1 - i])
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
		end
	end
end
