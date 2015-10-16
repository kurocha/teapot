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

require 'teapot/identity_set'

module Teapot::IdentitySetSpec
	describe Teapot::IdentitySet do
		NamedObject = Struct.new(:name, :age)
		
		let(:bob) {NamedObject.new('Bob', 10)}
		let(:empty_identity_set) {Teapot::IdentitySet.new}
		let(:bob_identity_set) {Teapot::IdentitySet.new([bob])}
		
		it "should contain named objects" do
			expect(bob_identity_set).to be_include bob
		end
		
		it "can enumerate all contained objects" do
			expect(bob_identity_set.each.to_a).to be == [bob]
		end
		
		it "could contain items" do
			expect(bob_identity_set).to_not be_empty
			expect(bob_identity_set.size).to be == 1
		end
		
		it "could be empty" do
			expect(empty_identity_set).to be_empty
		end
		
		it "could contain many items" do
			identity_set = empty_identity_set
			
			names = ["Apple", "Orange", "Banana", "Kiwifruit"]
			
			names.each_with_index do |name, index|
				identity_set << NamedObject.new(name, index)
			end
			
			expect(identity_set.size).to be == names.size
		end
		
		it "can be cleared" do
			identity_set = bob_identity_set.dup
			
			expect(identity_set).to_not be_empty
			
			identity_set.clear
			
			expect(identity_set).to be_empty
		end
		
		it "can remove items" do
			identity_set = bob_identity_set.dup
			
			expect(identity_set).to_not be_empty
			
			identity_set.remove(bob)
			
			expect(identity_set).to be_empty
		end
		
		it "can be frozen" do
			empty_identity_set.freeze
			
			expect(empty_identity_set).to be_frozen
		end
		
		it "can look up named items" do
			expect(bob_identity_set[bob.name]).to be == bob
		end
		
		it "should have string representation" do
			expect(bob_identity_set.to_s).to be =~ /Bob/
		end
	end
end