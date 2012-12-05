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

require 'pathname'
require 'test/unit'
require 'stringio'

require 'teapot/provider'

class TestProvider < Test::Unit::TestCase
	class BasicProvider
		include Teapot::Provider
	end
	
	def test_provides
		a = BasicProvider.new
		
		a.provides 'apple' do
			fruit ['apple']
		end
		
		b = BasicProvider.new
		
		b.provides 'orange' do
			fruit ['orange']
		end
		
		environment = Teapot::Provider.environment_for(['apple', 'orange'], [a, b]).flatten
		assert_equal ['apple', 'orange'], environment[:fruit]

		environment = Teapot::Provider.environment_for(['apple'], [a, b]).flatten
		assert_equal ['apple'], environment[:fruit]
		
		environment = Teapot::Provider.environment_for(['orange'], [a, b]).flatten
		assert_equal ['orange'], environment[:fruit]
	end
	
	def test_chains
		a = BasicProvider.new
		
		a.provides 'apple' do
			fruit ['apple']
		end
		
		b = BasicProvider.new
		
		b.provides 'orange' do
			fruit ['orange']
		end
		
		c = BasicProvider.new
		
		c.provides 'fruit-juice' do
			juice ['ice', 'cold']
		end
		
		c.depends 'apple'
		c.depends 'orange'
		
		chain = Teapot::Provider::dependency_chain(['fruit-juice'], [a, b, c])
		assert_equal [a, b, c], chain[:ordered].collect(&:first)
		
		d = BasicProvider.new
		
		d.provides 'pie' do
		end
		
		d.depends 'apple'
		
		chain = Teapot::Provider::dependency_chain(['pie'], [a, b, c, d])
		assert_equal [], chain[:unresolved]
		assert_equal [a, d], chain[:ordered].collect(&:first)
	end
end
