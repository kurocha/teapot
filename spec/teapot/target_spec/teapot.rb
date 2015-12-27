
teapot_version "1.0"

# Variants
define_target "variant-debug" do |target|
	target.priority = 20
	
	target.provides "Variant/debug" do
		default variant "debug"
		
		append buildflags %W{-O0 -g -Wall -Wmissing-prototypes}
		append linkflags %W{-g}
	end
	
	target.provides :variant => "Variant/debug"
end

define_target "variant-release" do |target|
	target.provides "Variant/release" do
		default variant "release"
		
		append buildflags %W{-O3 -DNDEBUG}
	end
	
	target.provides :variant => "Variant/release"
end

# Platforms
define_target "platform-generic" do |target|
	target.provides "Platform/generic" do
		default platform_name "generic"
		
		default build_prefix {platforms_path + "cache/#{platform_name}-#{variant}"}
		default install_prefix {platforms_path + "#{platform_name}-#{variant}"}
	end
	
	target.provides :platform => "Platform/generic"
end

# Test Targets
define_target "target_spec" do |target|
	target.provides "Test/TargetSpec" do
		append targets 'target_spec'
		flags ['foo']
	end
	
	target.depends :variant
	target.depends :platform
end

define_configuration "target_spec" do |configuration|
end
