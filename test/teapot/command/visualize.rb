# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "teapot/command"
require "teapot/command/visualize_context"

describe Teapot::Command::Visualize do
	include Teapot::Command::VisualizeContext
	
	let(:top) {Teapot::Command::Top["--root", project_path.to_s]}
	
	with "targets subcommand" do
		with "generate mermaid diagram" do
			let(:output_path) {File.join(root, "diagram.mmd")}
			let(:subject) {top["visualize", "targets", "-o", output_path]}
			
			it "should generate a Mermaid diagram" do
				diagram = subject.call
				
				# Verify it's a Mermaid flowchart
				expect(diagram).to be =~ /flowchart LR/
				
				# Verify it contains target dependencies
				expect(diagram).to be =~ /test-target/
				expect(diagram).to be =~ /library/
				
				# Also verify the file was written
				expect(File).to be(:exist?, output_path)
			end
		end
		
		with "save to file" do
			let(:output_path) {File.join(root, "dependencies.mmd")}
			let(:subject) {top["visualize", "targets", "-o", output_path]}
			
			it "should save Mermaid diagram to file" do
				subject.call
				
				expect(File).to be(:exist?, output_path)
				
				content = File.read(output_path)
				expect(content).to be =~ /flowchart LR/
				expect(content).to be =~ /test-target/
			end
		end
	end
	
	with "packages subcommand" do
		let(:output_path) {File.join(root, "packages.mmd")}
		let(:subject) {top["visualize", "packages", "-o", output_path]}
		
		it "should generate package dependency diagram" do
			diagram = subject.call
			
			# Verify it's a Mermaid flowchart
			expect(diagram).to be =~ /flowchart LR/
			
			# Verify the file was written
			expect(File).to be(:exist?, output_path)
		end
	end
end
