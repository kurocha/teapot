#!/usr/bin/env ruby
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
	module Merge
		Difference = Struct.new(:type, :value)
		
		def self.combine(old_text, new_text)
			lcs = lcs(old_text, new_text)
			changes = []
			
			n = 0; o = 0; l = 0
			while o < old_text.size and n < new_text.size and l < lcs.size
				if !similar(old_text[o], lcs[l])
					changes << Difference.new(:old, old_text[o])
					o+=1
				elsif !similar(new_text[n], lcs[l])
					changes << Difference.new(:new, new_text[n])
					n+=1
				else
					changes << Difference.new(:both, lcs[l])
					o+=1; n+=1; l+=1
				end
			end

			changes.map do |change|
				change.value
			end
		end

		# This code is based directly on the Text gem implementation
		# Returns a value representing the "cost" of transforming str1 into str2
		def self.levenshtein_distance(s, t)
			n = s.length
			m = t.length

			return m if n == 0
			return n if m == 0

			d = (0..m).to_a
			x = nil

			n.times do |i|
				e = i+1

				m.times do |j|
					cost = (s[i] == t[j]) ? 0 : 1
					x = [
						d[j+1] + 1, # insertion
						e + 1,      # deletion
						d[j] + cost # substitution
					].min
					d[j] = e
					e = x
				end

				d[m] = x
			end

			return x
		end

		# Calculate the similarity of two sequences, return true if they are with factor% similarity.
		def self.similar(s, t, factor = 0.15)
			return true if s == t
			
			distance = levenshtein_distance(s, t)
			average_length = (s.length + t.length) / 2.0

			proximity = (distance.to_f / average_length)
			
			return proximity <= factor
		end

		LCSNode = Struct.new(:value, :previous)
		
		# Find the Longest Common Subsequence in the given sequences x, y.
		def self.lcs(x, y)
			# Create the lcs matrix:
			m = Array.new(x.length + 1) do
				Array.new(y.length + 1) do
					LCSNode.new(nil, nil)
				end
			end

			# LCS(i, 0) and LCS(0, j) are always 0:
			for i in 0..x.length do m[i][0].value = 0 end
			for j in 0..y.length do m[0][j].value = 0 end

			# Main algorithm, solve row by row:
			for i in 1..x.length do
				for j in 1..y.length do
					if similar(x[i-1], y[j-1])
						# Value is based on maximizing the length of the matched strings:
						m[i][j].value = m[i-1][j-1].value + (x[i-1].chomp.length + y[j-1].chomp.length) / 2.0
						m[i][j].previous = [-1, -1]
					else
						if m[i-1][j].value >= m[i][j-1].value
							m[i][j].value = m[i-1][j].value
							m[i][j].previous = [-1, 0]
						else
							m[i][j].value = m[i][j-1].value
							m[i][j].previous = [0, -1]
						end
					end
				end
			end

			# Get the solution by following the path backwards from m[x.length][y.length]
			lcs = []
			
			i = x.length; j = y.length
			until m[i][j].previous == nil do
				if m[i][j].previous == [-1, -1]
					lcs << x[i-1]
				end
				
				i, j = i + m[i][j].previous[0], j + m[i][j].previous[1]
			end

			return lcs.reverse!
		end
	end
end
