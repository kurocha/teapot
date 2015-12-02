
teapot_version "1.0"

define_target "target_spec" do |target|
	target.provides "Test/TargetSpec" do
		append targets 'target_spec'
		flags ['foo']
	end
end

define_target "target_spec_with_dependencies" do |target|
	target.depends "Test/TargetSpec"
	
	target.provides "Test/TargetSpecWithDependencies"
end

define_configuration "target_spec" do |configuration|
end
