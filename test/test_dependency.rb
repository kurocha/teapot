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

require 'teapot/dependency'

class TestDependency < Test::Unit::TestCase
	class BasicDependency
		include Teapot::Dependency
		
		def initialize(name = nil)
			@name = name
		end
		
		attr :name
	end
	
	def test_chains
		a = BasicDependency.new
		
		a.provides 'apple' do
			fruit ['apple']
		end
		
		b = BasicDependency.new
		
		b.provides 'orange' do
			fruit ['orange']
		end
		
		c = BasicDependency.new
		
		c.provides 'fruit-juice' do
			juice ['ice', 'cold']
		end
		
		c.depends 'apple'
		c.depends 'orange'
		
		chain = Teapot::Dependency::chain([], ['fruit-juice'], [a, b, c])
		assert_equal [a, b, c], chain.ordered.collect(&:first)
		
		d = BasicDependency.new
		
		d.provides 'pie' do
		end
		
		d.depends 'apple'
		
		chain = Teapot::Dependency::chain([], ['pie'], [a, b, c, d])
		assert_equal [], chain.unresolved
		assert_equal [a, d], chain.ordered.collect(&:first)
	end
	
	def test_conflicts
		apple = BasicDependency.new('apple')
		apple.provides 'apple'
		apple.provides 'fruit'
		
		bananna = BasicDependency.new('bananna')
		bananna.provides 'fruit'
		
		salad = BasicDependency.new('salad')
		salad.depends 'fruit'
		salad.provides 'salad'
		
		chain = Teapot::Dependency::chain([], ['salad'], [apple, bananna, salad])
		assert_equal ["fruit", salad], chain.unresolved.first
		assert_equal({"fruit" => [apple, bananna]}, chain.conflicts)
		
		chain = Teapot::Dependency::chain(['apple'], ['salad'], [apple, bananna, salad])
		assert_equal([], chain.unresolved)
		assert_equal({}, chain.conflicts)
	end
	
	def test_aliases
		apple = BasicDependency.new('apple')
		apple.provides 'apple'
		apple.provides :fruit => 'apple'
		
		bananna = BasicDependency.new('bananna')
		bananna.provides 'bananna'
		bananna.provides :fruit => 'bananna'
		
		salad = BasicDependency.new('salad')
		salad.depends :fruit
		salad.provides 'salad'
		
		chain = Teapot::Dependency::chain(['apple'], ['salad'], [apple, bananna, salad])
		assert_equal([], chain.unresolved)
		assert_equal({}, chain.conflicts)
		assert_equal([[apple, "apple"], [salad, "salad"]], chain.ordered)
	end
end
