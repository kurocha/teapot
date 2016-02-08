
teapot_version "1.0"

$log = []

define_target "A" do |target|
	target.build do
		$log << :a_enter
		run! "sleep 5"
		$log << :a_exit
	end
	
	target.provides "Teapot/A"
end

define_target "B" do |target|
	target.build do
		$log << :b_enter
		run! "sleep 5"
		$log << :b_exit
	end
	
	target.provides "Teapot/B"
end

define_target "C" do |target|
	target.build do
		$log << :c_enter
		# This should not execute until A and B have completed.
		run! "sleep 5"
		$log << :c_exit
	end
	
	target.depends "Teapot/A"
	target.depends "Teapot/B"
	
	target.provides "Teapot/C"
end

define_configuration "wait_spec" do |configuration|
end
