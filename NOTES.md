# Notes

These are just some random design notes.

## Target build vs environment

It's cumbersome and causes a disconnect between `target.build` and environment provisions. Currently, it's written like this:

```ruby
define_target 'time-library' do |target|
	source_root = target.package.path + 'source'
	
	target.build do
		build prefix: target.name, static_library: "Time", source_files: source_root.glob('Time/**/*.cpp')
	end
	
	target.depends 'Build/Files'
	target.depends 'Build/Clang'
	
	target.depends :platform
	target.depends "Language/C++11", private: true
	
	target.depends "Build/Files"
	target.depends "Build/Clang"
	
	target.provides "Library/Time" do
		append linkflags [
			->{build_prefix + target.name + 'Time.a'},
		]
		
		append buildflags [
			"-I", ->{source_root},
		]
	end
end
```

Ideally, it's defined all in the environment:

```
target.provides "Library/Time" do
	append linkflags do
		build prefix: target.name, static_library: "Time", source_files: source_root.glob('Time/**/*.cpp')
	end
	
	append buildflags [
		"-I", ->{source_root},
	]
end
```

Perhaps with the ability to share build steps:

```ruby
append linkflags &target.build
```

## Modern format for package definitions.

define_target 'test-project-library' do |target|
	source_root = target.package.path + 'source'
	
	target.depends 'Language/C++14', private: true
	
	target.provides 'Library/TestProject' do
		append include_paths source_root
		
		library_path = build static_library: 'TestProject', source_files: source_root.glob('TestProject/**/*.cpp')
		
		append linkflags library_path
	end
end
