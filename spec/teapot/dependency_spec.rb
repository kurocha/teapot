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

require 'teapot/dependency'

module Teapot::DependencySpec
	class BasicDependency
		include Teapot::Dependency
		
		def initialize(name = nil)
			@name = name
		end
		
		attr :name
	end
	
	describe Teapot::Dependency do
		it "Should resolve dependency chain" do
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
			expect(chain.ordered.collect(&:first)).to be == [a, b, c]
		
			d = BasicDependency.new
		
			d.provides 'pie' do
			end
		
			d.depends 'apple'
		
			chain = Teapot::Dependency::chain([], ['pie'], [a, b, c, d])
			
			expect(chain.unresolved).to be == []
			expect(chain.ordered.collect(&:first)).to be == [a, d]
		end
		
		it "should report conflicts" do
			apple = BasicDependency.new('apple')
			apple.provides 'apple'
			apple.provides 'fruit'
		
			bananna = BasicDependency.new('bananna')
			bananna.provides 'fruit'
		
			salad = BasicDependency.new('salad')
			salad.depends 'fruit'
			salad.provides 'salad'
		
			chain = Teapot::Dependency::Chain.new([], ['salad'], [apple, bananna, salad])
			expect(chain.unresolved.first).to be == ["fruit", salad]
			expect(chain.conflicts).to be == {"fruit" => [apple, bananna]}
		
			chain = Teapot::Dependency::Chain.new(['apple'], ['salad'], [apple, bananna, salad])
			expect(chain.unresolved).to be == []
			expect(chain.conflicts).to be == {}
		end
		
		it "should resolve aliases" do
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
			expect(chain.unresolved).to be == []
			expect(chain.conflicts).to be == {}
			expect(chain.ordered).to be == [[apple, "apple"], [salad, "salad"]]
		end
	end
end
