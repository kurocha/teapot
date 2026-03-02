
define_target 'test-project-library' do |target|
	source_root = target.package.path + 'source'
	
	target.depends 'Language/C++14', private: true
	
	target.provides 'Library/TestProject' do
		append include_paths source_root
		
		library_path = build static_library: 'TestProject', source_files: source_root.glob('TestProject/**/*.cpp')
		
		append linkflags library_path
	end
end
