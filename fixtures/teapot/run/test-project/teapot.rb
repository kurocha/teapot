# frozen_string_literal: true

define_project "test-project" do |project|
	project.title = "Test Project"
	project.license = "MIT"
end

define_target "test-target" do |target|
	target.depends "library"
end

define_target "library" do |target|
end
